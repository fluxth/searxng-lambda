FROM public.ecr.aws/lambda/python:3.11-preview.2023.07.12.05@sha256:bf635ff7c778dbd9689e69d477c863d1bbef7ff0e896666203ae94eeba7ade73 AS base

RUN yum install -y libxml2 libxslt && \
    yum clean all && \
    rm -rf /var/cache/yum

FROM base AS build
WORKDIR /tmp/workdir

RUN yum install -y gcc libxml2-devel libxslt-devel patch

COPY searxng/requirements.txt .
COPY requirements.txt ./requirements.lambda.txt

RUN sed -i 's/pytomlpp.*//' requirements.txt

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
