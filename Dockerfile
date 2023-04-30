FROM public.ecr.aws/lambda/python:3.10.2023.04.17.20-arm64 as build

COPY searxng/requirements.txt .
COPY requirements.txt ./requirements.lambda.txt

RUN pip3 install -r requirements.txt --target "${LAMBDA_TASK_ROOT}" && \
    pip3 install -r requirements.lambda.txt --target "${LAMBDA_TASK_ROOT}"

COPY searxng/searx ${LAMBDA_TASK_ROOT}/searx

RUN cd ${LAMBDA_TASK_ROOT} && \
    python3 -m compileall -q searx

COPY settings.yml main.py ${LAMBDA_TASK_ROOT}

FROM public.ecr.aws/lambda/python:3.10.2023.04.17.20-arm64 as runtime

ENV INSTANCE_NAME=searxng \
    AUTOCOMPLETE= \
    BASE_URL= \
    MORTY_KEY= \
    MORTY_URL= \
    SEARXNG_SETTINGS_PATH=${LAMBDA_TASK_ROOT}/settings.yml

COPY --from=build ${LAMBDA_TASK_ROOT} ${LAMBDA_TASK_ROOT}

CMD ["main.lambda_handler"]
