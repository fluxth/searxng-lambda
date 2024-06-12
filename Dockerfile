FROM public.ecr.aws/lambda/python:3.12.2024.06.10.10@sha256:7a279a376245d08ba5396c9fbed4fb3daa64fa810c6b54f8249cbd08ebed1362 AS base

RUN dnf install -y libxml2 libxslt && \
    dnf clean all && \
    rm -rf /var/cache/dnf

FROM base AS build
WORKDIR /tmp/workdir

RUN dnf install -y gcc gcc-c++ libxml2-devel libxslt-devel

COPY searxng/requirements.txt .
COPY requirements.txt ./requirements.lambda.txt

RUN echo >> requirements.txt && \
    cat requirements.txt requirements.lambda.txt > requirements.all.txt && \
    pip3 install -r requirements.all.txt --target "${LAMBDA_TASK_ROOT}"

COPY searxng/searx ${LAMBDA_TASK_ROOT}/searx
COPY main.py ${LAMBDA_TASK_ROOT}

RUN cd ${LAMBDA_TASK_ROOT} && \
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
