# python-36-gdal
FROM centos/s2i-base-centos7

# Inform users who's the maintainer of this builder image
MAINTAINER Ashley Felton <ashley@ropable.com>

# Specify the ports the final image will expose
EXPOSE 8080

ENV PYTHON_VERSION=3.6 \
    PATH=$HOME/.local/bin/:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    PIP_NO_CACHE_DIR=off \
    GDAL_VERSION=2.2.3 \
    SUMMARY="Platform for building and running Python $PYTHON_VERSION applications" \
    DESCRIPTION="Python $PYTHON_VERSION available as docker container is a base platform for \
building and running various Python $PYTHON_VERSION applications and frameworks. \
Includes a compiled version of GDAL $GDAL_VERSION to allow spatial data processing."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="Python 3.6 with GDAL" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,python,python36,rh-python36,gdal" \
      io.openshift.s2i.scripts-url=image:///usr/local/s2i \
      com.redhat.component="rh-python36-docker" \
      name="rhscl/python-36-rhel7-gdal" \
      version="1"

RUN yum install -y yum-utils && \
    prepare-yum-repositories rhel-server-rhscl-7-rpms && \
    INSTALL_PKGS="rh-python36 rh-python36-python-devel rh-python36-python-setuptools rh-python36-python-pip \
    nss_wrapper atlas-devel gcc-gfortran libffi-devel libtool-ltdl enchant wget" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    # Download GDAL
    wget http://download.osgeo.org/gdal/$GDAL_VERSION/gdal-$GDAL_VERSION.tar.gz && \
    tar xzf gdal-$GDAL_VERSION.tar.gz && \
    cd gdal-$GDAL_VERSION && \
    # Compile GDAL from source.
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf gdal-$GDAL_VERSION && \
    yum clean all -y


# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH.
#COPY ./s2i/bin/ $STI_SCRIPTS_PATH
COPY ./s2i/bin/ /usr/local/s2i

# - Create a Python virtual environment for use by any application to avoid
#   potential conflicts with Python packages preinstalled in the main Python
#   installation.
# - In order to drop the root user, we have to make some directories world
#   writable as OpenShift default security model is to run the container
#   under random UID.
RUN source scl_source enable rh-python36 && \
    virtualenv ${APP_ROOT} && \
    chown -R 1001:1001 ${APP_ROOT} && \
    fix-permissions ${APP_ROOT} -P && \
    rpm-file-permissions

# This default user is created in the openshift/base-centos7 image
USER 1001

# Set the default CMD for the image
CMD ["usage"]
