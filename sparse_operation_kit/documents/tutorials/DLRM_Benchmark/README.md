# SOK DLRM Benchmark

This document demonstrates how to prepare the dataset and run SOK DLRM benchmark.

## How to Prepare Dataset
We provide two approaches to prepare data: using Criteo Terabyte dataset directly or generate synthetic dataset with HugeCTR data generator below.

### How to Prepare Criteo Terabyte Dataset

```bash
git clone https://github.com/NVIDIA-Merlin/HugeCTR.git
cd HugeCTR/
cd sparse_operation_kit/documents/tutorials/DLRM_Benchmark/
# train_data.bin and test_data.bin is the binary dataset generated by hugectr
# $DATA is the target directory to save the splited dataset
python3 split_bin.py train_data.bin $DATA/train --slot_size_array="[39884406,39043,17289,7420,20263,3,7120,1543,63,38532951,2953546,403346,10,2208,11938,155,4,976,14,39979771,25641295,39664984,585935,12972,108,36]"

python3 split_bin.py test_data.bin $DATA/test --slot_size_array="[39884406,39043,17289,7420,20263,3,7120,1543,63,38532951,2953546,403346,10,2208,11938,155,4,976,14,39979771,25641295,39664984,585935,12972,108,36]"
```

### How to Prepare Synthetic Dataset

* Step 1, start a container with native HugeCTR

Merlin NGC container with native HugeCTR can be used directly: nvcr.io/nvidia/merlin/merlin-training:22.05 

To start the container, you can refer to the related instructions [here](https://gitlab-master.nvidia.com/dl/hugectr/hugectr#getting-started)

```bash
# $YourDataDir is the target directory to save the synthetic dataset
docker run --privileged=true --gpus=all -it --rm -v $YourDataDir:/home/workspace nvcr.io/nvidia/merlin/merlin-training:22.05
cd /home/workspace
```

* Step2, run the following script to generate a synthetic dataset, you can modify `num_samples` and `eval_num_samples` as you want.

```python
# python
import hugectr
from hugectr.tools import DataGenerator, DataGeneratorParams

data_generator_params = DataGeneratorParams(
  format = hugectr.DataReaderType_t.Raw,
  label_dim = 1,
  dense_dim = 13,
  num_slot = 26,
  i64_input_key = False,
  source = "./dlrm_raw/train_data.bin",
  eval_source = "./dlrm_raw/test_data.bin",
  slot_size_array = [203931, 18598, 14092, 7012, 18977, 4, 6385, 1245, 49, 186213, 71328, 67288, 11, 2168, 7338, 61, 4, 932, 15, 204515, 141526, 199433, 60919, 9137, 71, 34],
  nnz_array = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  num_samples = 5242880,
  eval_num_samples = 1310720
)
data_generator = DataGenerator(data_generator_params)
data_generator.generate()
```

* Step 3, split the binary file

```bash
cd /home/workspace
git clone https://github.com/NVIDIA-Merlin/HugeCTR.git

# Note: the `--slot_size_array` should be the same as the slot_size_array in step 2.
python3 HugeCTR/sparse_operation_kit/documents/tutorials/DLRM_Benchmark/preprocess/split_bin.py ./dlrm_raw/train_data.bin ./splited_dataset/train/ --slot_size_array="[203931,18598,14092,7012,18977,4,6385,1245,49,186213,71328,67288,11,2168,7338,61,4,932,15,204515,141526,199433,60919,9137,71,34]"

# Note: the `--slot_size_array` should be the same as the slot_size_array in step 2.
python3 HugeCTR/sparse_operation_kit/documents/tutorials/DLRM_Benchmark/preprocess/split_bin.py ./dlrm_raw/test_data.bin ./splited_dataset/test/ --slot_size_array="[203931,18598,14092,7012,18977,4,6385,1245,49,186213,71328,67288,11,2168,7338,61,4,932,15,204515,141526,199433,60919,9137,71,34]"
```

## Environment

```bash
# $YourDataDir is the directory where you saved the dataset
docker run --privileged=true --gpus=all -it --rm -v $YourDataDir:/home/workspace nvcr.io/nvidia/merlin/merlin-tensorflow-training:22.05
```

## How to Run Benchmark

```bash
git clone https://github.com/NVIDIA-Merlin/HugeCTR.git
cd HugeCTR/sparse_operation_kit/documents/tutorials/DLRM_Benchmark/

# FP32 Result with global batch size = 65536
# Note that --lr=24 is tested on real criteo dataset. This learning rate is too large for a synthetic dataset and it is likely to cause the loss to become nan
horovodrun -np 8 ./hvd_wrapper.sh python3 main.py --data_dir=/home/workspace/splited_dataset/ --global_batch_size=65536 --xla --compress --eval_in_last --epochs=1000 --lr=24

# AMP result with global batch size = 65536
horovodrun -np 8 ./hvd_wrapper.sh python3 main.py --data_dir=/home/workspace/splited_dataset/ --global_batch_size=65536 --xla --amp --eval_in_last --epochs=1000 --lr=24

# FP32 Result with global batch size = 55296
horovodrun -np 8 ./hvd_wrapper.sh python3 main.py --data_dir=/home/workspace/splited_dataset/ --global_batch_size=55296 --xla --compress --epochs=1000 --lr=24

# AMP result with global batch size = 55296
horovodrun -np 8 ./hvd_wrapper.sh python3 main.py --data_dir=/home/workspace/splited_dataset/ --global_batch_size=55296 --xla --amp --epochs=1000 --lr=24
```

Note: For better performance, you can use a custom interact op provided by [here](https://github.com/NVIDIA/DeepLearningExamples/tree/master/TensorFlow2/Recommendation/DLRM/tensorflow-dot-based-interact). After installing the custom interact op, you can add `--custom_interact` to the instructions below (This is optional). Detailed performance can be found on the tables below.

## Performance

### Performance on 8 x A100

| batch size | exit criteria | frequent of evaluation | xla | custom interact | amp | compress | training time (minutes) | evaluating time (minutes) | total time (minutes) | average time of iteration (ms) | throughput(samples/second) |
| :---: | :---:        | :---:            | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---:  |
| 65536 | 1 epoch      | at end           | yes   | yes   | no    | yes   | 8.79  | 0.10  | 8.89  | 8.25  | 8.16M  |
| 65536 | 1 epoch      | at end           | yes   | yes   | yes   | no    | 6.72  | 0.09  | 6.81  | 6.30  | 10.78M |
| 55296 | AUC > 0.8025 | every 3793 steps | yes   | yes   | no    | yes   | 8.04  | 1.59  | 9.63  | 7.48  | 7.60M  |
| 55296 | AUC > 0.8025 | every 3793 steps | yes   | yes   | yes   | no    | 6.52  | 1.94  | 8.46  | 6.07  | 10.45M |

### Performance on 8 x V100

| batch size | exit criteria | frequent of evaluation | xla | custom interact | amp | compress | training time (minutes) | evaluating time (minutes) | total time (minutes) | average time of iteration (ms) | throughput(samples/second) |
| :---: | :---:        | :---:            | :---: | :---: | :---: | :---: | :---:  | :---: | :---:  | :---:  | :---: |
| 65536 | 1 epoch      | at end           | yes   | yes   | no    | yes   | 19.25  | 0.21  | 19.46  | 18.04  | 3.66M |
| 65536 | 1 epoch      | at end           | yes   | yes   | yes   | no    | 12.91  | 0.19  | 13.10  | 12.10  | 5.53M |
| 55296 | AUC > 0.8025 | every 3793 steps | yes   | yes   | no    | yes   | 18.48  | 4.03  | 22.51  | 16.24  | 3.45M |
| 55296 | AUC > 0.8025 | every 3793 steps | yes   | yes   | yes   | no    | 12.11  | 3.18  | 15.29  | 10.65  | 5.36M |

### Performance with custom interact op

* 8 x A100 (82GB embedding table) with custom interact op:

| batch size | exit criteria | frequent of evaluation | xla | custom interact | amp | compress | training time (minutes) | evaluating time (minutes) | total time (minutes) | average time of iteration (ms) | throughput(samples/second) |
| :---: | :---:        | :---:            | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---:  |
| 65536 | 1 epoch      | at end           | yes   | yes   | no    | yes   | 5.93  | 0.09  | 6.02  | 5.55  | 12.08M |
| 65536 | 1 epoch      | at end           | yes   | yes   | yes   | no    | 5.06  | 0.07  | 5.13  | 4.74  | 14.51M |
| 55296 | AUC > 0.8025 | every 3793 steps | yes   | yes   | no    | yes   | 5.23  | 1.44  | 6.67  | 4.87  | 11.66M |
| 55296 | AUC > 0.8025 | every 3793 steps | yes   | yes   | yes   | no    | 4.99  | 1.26  | 6.25  | 4.64  | 12.50M |

* 8 x V100 (82GB embedding table) with custom interact op:

| batch size | exit criteria | frequent of evaluation | xla | custom interact | amp | compress | training time (minutes) | evaluating time (minutes) | total time (minutes) | average time of iteration (ms) | throughput(samples/second) |
| :---: | :---:        | :---:            | :---: | :---: | :---: | :---: | :---:  | :---: | :---:  | :---:  | :---: |
| 65536 | 1 epoch      | at end           | yes   | yes   | no    | yes   | 17.52  | 0.19  | 17.71  | 16.42  | 4.02M |
| 65536 | 1 epoch      | at end           | yes   | yes   | yes   | no    | 10.20  | 0.15  | 10.35  | 9.56   | 6.99M |
| 55296 | AUC > 0.8025 | every 3793 steps | yes   | yes   | no    | yes   | 16.45  | 3.59  | 20.04  | 14.45  | 3.85M |
| 55296 | AUC > 0.8025 | every 3793 steps | yes   | yes   | yes   | no    | 9.69   | 2.54  | 12.23  | 8.52   | 6.62M |

## Profile

```bash
cd HugeCTR/sparse_operation_kit/documents/tutorials/DLRM_Benchmark/
nsys profile --sample=none --backtrace=none --cudabacktrace=none --cpuctxsw=none --trace-fork-before-exec=true horovodrun -np 8 ./hvd_wrapper.sh python3 main.py --data_dir=($DATA) --global_batch_size=65536 --xla --compress --custom_interact --early_stop=30
```
