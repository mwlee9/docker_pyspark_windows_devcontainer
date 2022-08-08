FROM python:3.7.7 as compile-image

### Set Pyspark Python Paths so that Driver and Executor are consistent
ENV PYTHONPATH=/usr/bin/python3.7
ENV PYSPARK_PYTHON=/usr/bin/python3.7
ENV PYSPARK_DRIVER_PYTHON=/usr/bin/python3.7

### Setup a virtual env for python isolation and smaller image sizes on multi-stage builds.
### Allows us to easily copy over the files in one bundle from compile container to build.
ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

### Copy requirements file and install packages to the venv (hence no --user flag).
### If VENV is not used, --user flag must be on pip install otherwise git and requirements deps will collide.
### Adjust this file before build to add additional modules, minimal build to save on space
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

### Install Jupyter and extensions
RUN python -m pip install --no-cache-dir jupyterlab jupyter_contrib_nbextensions jupyter_nbextensions_configurator

########################################################################################
### Change to the slim image to save on space - ONLY RECOMMENDED FOR STANDALONE PY APPS, according to Python Docker Repo.
FROM python:3.7.7 AS build-image

### Set the venv to path
ENV PATH="/opt/venv/bin:$PATH"

### Need to make this directory for openjdk to install properly
RUN mkdir -p /usr/share/man/man1

### Install next round of linux dependencies that will need to persist in this stage. These are for MS SQL Server connection.
RUN apt-get update && apt-get install -y --no-install-recommends libaio1 openjdk-11-jre-headless openjdk-11-jdk-headless ca-certificates-java wget && \
    rm -rf /var/lib/apt/lists/*

# Fix DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Spark dependencies
# Default values can be overridden at build time
# (ARGS are in lower case to distinguish them from ENV)
ARG spark_version="3.3.0"
ARG hadoop_version="3"
ARG spark_checksum="1e8234d0c1d2ab4462d6b0dfe5b54f2851dcd883378e0ed756140e10adfb5be4123961b521140f580e364c239872ea5a9f813a20b73c69cb6d4e95da2575c29c"
ARG openjdk_version="11"

ENV APACHE_SPARK_VERSION="${spark_version}" \
    HADOOP_VERSION="${hadoop_version}"

RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    "openjdk-${openjdk_version}-jre-headless" \
    ca-certificates-java && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Spark installation
WORKDIR /tmp
RUN wget -q "https://archive.apache.org/dist/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    echo "${spark_checksum} *spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" | sha512sum -c - && \
    tar xzf "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" -C /usr/local --owner root --group root --no-same-owner && \
    rm "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"

WORKDIR /usr/local

# Configure Spark
ENV SPARK_HOME=/usr/local/spark
ENV SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" \
    PATH="${PATH}:${SPARK_HOME}/bin"

RUN ln -s "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" spark && \
    # Add a link in the before_notebook hook in order to source automatically PYTHONPATH
    mkdir -p /usr/local/bin/before-notebook.d && \
    ln -s "${SPARK_HOME}/sbin/spark-config.sh" /usr/local/bin/before-notebook.d/spark-config.sh

# Fix Spark installation for Java 11 and Apache Arrow library
# see: https://github.com/apache/spark/pull/27356, https://spark.apache.org/docs/latest/#downloading
RUN cp -p "${SPARK_HOME}/conf/spark-defaults.conf.template" "${SPARK_HOME}/conf/spark-defaults.conf" && \
    echo 'spark.driver.extraJavaOptions -Dio.netty.tryReflectionSetAccessible=true' >> "${SPARK_HOME}/conf/spark-defaults.conf" && \
    echo 'spark.executor.extraJavaOptions -Dio.netty.tryReflectionSetAccessible=true' >> "${SPARK_HOME}/conf/spark-defaults.conf"

### Copy in a conf file to point to the right drivers (oracle thin jdbc driver outlined here)
COPY spark-defaults.conf ${SPARK_HOME}/conf/spark-defaults.conf

WORKDIR /home/

### Copy the files from the previous stage to save on space and remove secrets.
COPY --from=compile-image /opt/venv /opt/venv

### Change style of pyspark dataframes to pretty print
COPY style.min.css /opt/venv/lib/python3.7/site-packages/notebook/static/style/style.min.css

### Install Jupyter extensions and enable them
RUN jupyter contrib nbextension install --user
RUN jupyter nbextensions_configurator enable --user

### Install Julia
RUN wget https://julialang-s3.julialang.org/bin/linux/x64/1.7/julia-1.7.0-linux-x86_64.tar.gz
RUN tar -xvzf julia-1.7.0-linux-x86_64.tar.gz
RUN cp -r julia-1.7.0 /opt/
RUN ln -s /opt/julia-1.7.0/bin/julia /usr/local/bin/julia
RUN julia -e 'using Pkg;Pkg.add("IJulia")'

CMD ["jupyter", "lab", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root", "--NotebookApp.token=''"]

### Here for documentation, doesn't actually expose the port.
EXPOSE 8888