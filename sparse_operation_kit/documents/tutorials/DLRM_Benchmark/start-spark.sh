#!/bin/bash -x
${SPARK_HOME}/sbin/start-master.sh -h ${SPARK_PUBLIC_DNS}
${SPARK_HOME}/sbin/start-worker.sh ${SPARK_URL}



