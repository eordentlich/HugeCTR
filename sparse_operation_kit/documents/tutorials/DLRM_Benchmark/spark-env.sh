export SPARK_WORKER_OPTS="-Dspark.worker.resource.gpu.amount=2 -Dspark.worker.resource.gpu.discoveryScript=${SPARK_HOME}/examples/src/main/scripts/getGpusResources.sh"
export SPARK_PUBLIC_DNS=127.0.0.1
export SPARK_WORKER_WEBUI_PORT=8082
export SPARK_WORKER_INSTANCES=1
export PYSPARK_DRIVER_PYTHON=jupyter
#export PYSPARK_PYTHON=/criteo-demo-local/memcheck-python.sh
export PYSPARK_DRIVER_PYTHON_OPTS='notebook --ip=0.0.0.0 --allow-root'
export SPARK_URL=spark://${SPARK_PUBLIC_DNS}:7077
