FROM public.ecr.aws/awsguru/aws-lambda-adapter:0.7.1@sha256:97c8f81e19e64841df0882d3b3c943db964c554992c1bac26100f1d6c41ea0bb AS adapter
FROM public.ecr.aws/lambda/provided:al2.2023.10.20.00@sha256:d3a1468b44ede33f5b19ffd39fa59b7d4829b665ae69851ebf7d6d21898352aa AS rie

FROM searxng/searxng:2023.10.20-01b5b9cb8@sha256:73ffd1a6bec793505f57c8bdecce0821f52cad275edf02ad6ebf37b558635d2a AS searxng

COPY --from=adapter /lambda-adapter /opt/extensions/lambda-adapter
COPY --from=rie /usr/local/bin/aws-lambda-rie /usr/local/bin/aws-lambda-rie
COPY lambda-entrypoint.sh /lambda-entrypoint.sh
COPY settings.yml /etc/searxng/settings.yml

ENV BIND_ADDRESS=127.0.0.1:7000

ENV AWS_LWA_PORT=7000
ENV AWS_LWA_READINESS_CHECK_PORT=7000
ENV AWS_LWA_READINESS_CHECK_PATH=/healthz

ENTRYPOINT ["/lambda-entrypoint.sh"]
CMD ["/usr/local/searxng/dockerfiles/docker-entrypoint.sh"]
