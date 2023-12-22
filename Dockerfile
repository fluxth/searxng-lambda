FROM public.ecr.aws/lambda/python:3.12.2023.12.22.15@sha256:50efe1b81fa4fb589204b8e42868124f3fbc52d938dac58e4a230a5956c87a21 AS base

RUN dnf install -y libxml2 libxslt && \
    dnf clean all && \
    rm -rf /var/cache/dnf

FROM base AS build
WORKDIR /tmp/workdir

RUN dnf install -y gcc gcc-c++ libxml2-devel libxslt-devel patch

COPY searxng/requirements.txt .
COPY requirements.txt ./requirements.lambda.txt

RUN echo >> requirements.txt && \
    sed -i 's/pytomlpp.*//' requirements.txt

RUN cat requirements.txt requirements.lambda.txt > requirements.all.txt && \
    pip3 install -r requirements.all.txt --target "${LAMBDA_TASK_ROOT}"

COPY searxng/searx ${LAMBDA_TASK_ROOT}/searx
COPY main.py ${LAMBDA_TASK_ROOT}
COPY patches patches

RUN cd ${LAMBDA_TASK_ROOT} && \
    cat /tmp/workdir/patches/*.patch | patch -p1 && \
    python3 -m compileall searx main.py

COPY settings.yml ${LAMBDA_TASK_ROOT}

FROM base AS runtime

ENV INSTANCE_NAME=searxng \
    AUTOCOMPLETE= \
    BASE_URL= \
    MORTY_KEY= \
    MORTY_URL= \
    SEARXNG_SETTINGS_PATH=${LAMBDA_TASK_ROOT}/settings.yml

COPY --from=build ${LAMBDA_TASK_ROOT} ${LAMBDA_TASK_ROOT}

CMD ["main.lambda_handler"]
