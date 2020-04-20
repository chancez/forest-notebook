ARG quilc_version=1.16.1
ARG qvm_version=1.15.3
ARG pyquil_version=2.19.0
ARG BASE_CONTAINER=jupyter/scipy-notebook

# use multi-stage builds to independently pull dependency versions
FROM rigetti/quilc:$quilc_version as quilc
FROM rigetti/qvm:$qvm_version as qvm
FROM $BASE_CONTAINER
ARG pyquil_version

# change to root for installation of new packages
USER root

# install system packages
# pyquil
# TeXLive et al for circuit diagram generation
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libblas-dev libffi-dev liblapack-dev libzmq3-dev \
        ghostscript imagemagick texlive-latex-base texlive-latex-extra \
    && \
    rm -rf /var/lib/apt/lists/*

# copy over the pre-built quilc binary from the first build stage
COPY --from=quilc /src/quilc/quilc /usr/local/bin/quilc
# copy over the pre-built qvm binary from the second build stage
COPY --from=qvm /src/qvm/qvm /usr/local/bin/qvm

# Switch back to the notebook user
USER $NB_UID

# Add the rigetti conda channel
RUN conda config --add channels rigetti

# install pyquil, jupyter_forest_extension, and qcs CLI
RUN pip install \
    pyquil==$pyquil_version \
    pyquil[tutorials] \
    tqdm \
    && \
    npm install -g \
    qcs-cli \
    && \
    conda clean --all -f -y && \
    npm cache clean --force && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    rm -rf /home/$NB_USER/.node-gyp && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Default to jupyter lab instead of jupyter notebook
ENV JUPYTER_ENABLE_LAB true

# Run quilc and qvm in the background
COPY forest-entrypoint.sh /usr/local/bin/forest-entrypoint.sh
ENTRYPOINT ["tini", "-g", "--", "/usr/local/bin/forest-entrypoint.sh"]
CMD ["start-notebook.sh"]

COPY examples /tmp/forest-sdk-examples
COPY default.jupyterlab-workspace /tmp/default.jupyterlab-workspace
RUN jupyter lab workspaces import /tmp/default.jupyterlab-workspace
RUN cp -a /tmp/forest-sdk-examples /home/$NB_USER/forest-sdk-examples

# Fix permissions on example files
USER root
RUN fix-permissions /home/$NB_USER && chown -R $NB_UID /home/$NB_USER/forest-sdk-examples /tmp/forest-sdk-examples /tmp/default.jupyterlab-workspace

# Switch back to the notebook user
USER $NB_UID
