FROM public.ecr.aws/lambda/python:3.11-preview.2023.07.10.11@sha256:94ef6bf352fd80175ebcd561ec84c2f80daf27231269549df913cf36161f48dd AS base

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
