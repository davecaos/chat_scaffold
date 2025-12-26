FROM elixir:1.15-alpine

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files
COPY mix.exs ./

# Get dependencies
RUN mix deps.get

# Copy config and source
COPY config ./config
COPY lib ./lib

# Compile
RUN mix compile

EXPOSE 4000

CMD ["mix", "phx.server"]
