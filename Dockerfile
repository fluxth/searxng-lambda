FROM public.ecr.aws/lambda/python:3.11-preview.2023.05.29.18-arm64@sha256:595a04292297a9c2846ad23084dc847ac8624691474e40b227d2586fb3270e40 AS build

WORKDIR /tmp/workdir

RUN yum install -y patch

COPY searxng/requirements.txt .
COPY requirements.txt ./requirements.lambda.txt

RUN sed -i 's/pytomlpp.*//' requirements.txt

RUN pip3 install -r requirements.txt --target "${LAMBDA_TASK_ROOT}" && \
    pip3 install -r requirements.lambda.txt --target "${LAMBDA_TASK_ROOT}"

COPY searxng/searx ${LAMBDA_TASK_ROOT}/searx
COPY patches patches

RUN cd ${LAMBDA_TASK_ROOT} && \
    cat /tmp/workdir/patches/*.patch | patch -p1 && \
    python3 -m compileall searx main.py

COPY settings.yml main.py ${LAMBDA_TASK_ROOT}

FROM public.ecr.aws/lambda/python:3.11-preview.2023.05.29.18-arm64@sha256:595a04292297a9c2846ad23084dc847ac8624691474e40b227d2586fb3270e40 AS runtime

ENV INSTANCE_NAME=searxng \
    AUTOCOMPLETE= \
    BASE_URL= \
    MORTY_KEY= \
    MORTY_URL= \
    SEARXNG_SETTINGS_PATH=${LAMBDA_TASK_ROOT}/settings.yml

COPY --from=build ${LAMBDA_TASK_ROOT} ${LAMBDA_TASK_ROOT}

CMD ["main.lambda_handler"]
