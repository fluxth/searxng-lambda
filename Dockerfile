FROM public.ecr.aws/lambda/python:3.11-preview.2023.06.27.19-arm64@sha256:23c816fb2ed79e356b5a54ff17894de250250e255ac0ec2f00f5d5dc0c49366f AS base

FROM base AS build

WORKDIR /tmp/workdir

RUN yum install -y patch

COPY searxng/requirements.txt .
COPY requirements.txt ./requirements.lambda.txt

RUN sed -i 's/pytomlpp.*//' requirements.txt

RUN pip3 install -r requirements.txt --target "${LAMBDA_TASK_ROOT}" && \
    pip3 install -r requirements.lambda.txt --target "${LAMBDA_TASK_ROOT}"

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
