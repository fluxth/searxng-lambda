FROM public.ecr.aws/lambda/python:3.12.2024.03.24.02@sha256:5f04a5e231d238774b62a4900bcf7927838811047600583272d590956bbec940 AS base

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
