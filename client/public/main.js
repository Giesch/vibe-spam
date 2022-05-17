import { createClient, defaultExchanges, subscriptionExchange } from "urql";
import { createClient as createWSClient } from "graphql-ws";
import { pipe, subscribe } from "wonka";

import { Elm } from "../src/Main.elm";

// The id of an element containing json Elm flags
// NOTE this must match the id used in the root /templates/index.html
const FLAGS_DIV_ID = "elm-flags-json";

// NOTE this must match ROUTE in root /src/routes/graphql.rs
const GQL_ROUTE = "/api/graphql";

// NOTE this must match WS_ROUTE in root /src/routes/graphql.rs
const GQL_WS_ROUTE = "/api/graphql/ws";

/**
 * Starts the Elm app with the server-rendered flags (ie session data)
 *
 * @return {Promise<object>} app - the Elm application
 */
export async function init() {
  const serverFlags = await getFlagsForEnv();
  console.log({ serverFlags });

  const timeZone = new Intl.DateTimeFormat().resolvedOptions().timeZone;
  const flags = { ...serverFlags, timeZone };

  const wsUrl = getWebsocketUrlForEnv();

  const wsClient = createWSClient({ url: wsUrl });
  const gqlClient = createClient({
    url: GQL_ROUTE,
    exchanges: [
      ...defaultExchanges,
      subscriptionExchange({
        forwardSubscription: (operation) => ({
          subscribe: (sink) => ({
            unsubscribe: wsClient.subscribe(operation, sink),
          }),
        }),
      }),
    ],
  });

  const app = Elm.Main.init({ flags });

  app.ports.toJs.subscribe(({ kind, value }) => {
    console.log("recieved toJs msg:");
    console.log({ kind, value });

    switch (kind) {
      case "lobby-subscribe":
        pipe(
          gqlClient.subscription(value),

          subscribe((result) => {
            console.log("sending lobby-updated");

            app.ports.fromJs.send({
              kind: "lobby-updated",
              value: result,
            });
          })
        );

        break;

      case "chat-room-subscribe":
        const { roomTitle, document } = value;

        pipe(
          gqlClient.subscription(document),

          subscribe((result) => {
            console.log("sending chat-room-updated");

            app.ports.fromJs.send({
              kind: "chat-room-updated",
              value: { result, roomTitle },
            });
          })
        );

        break;
    }
  });

  return app;
}

/**
 * Gets the flags from either server-rendered
 * html (in prod) or json endpoint (in local dev).
 *
 * @return {Promise<object>} Elm app flags
 */
async function getFlagsForEnv() {
  if (import.meta.env.MODE === "development") {
    const response = await fetch("/api/flags");
    return response.json();
  } else {
    const flagsDiv = document.getElementById(FLAGS_DIV_ID);
    if (!flagsDiv) {
      return {};
    }

    try {
      return JSON.parse(flagsDiv.innerText);
    } catch {
      return {};
    }
  }
}

/**
 * Gets the websocket url to use for either the dev server or prod.
 * @return {string} websocket url
 */
function getWebsocketUrlForEnv() {
  if (import.meta.env.MODE === "development") {
    return `ws://localhost:8000${GQL_WS_ROUTE}`;
  } else {
    return `wss://${window.location.hostname}${GQL_WS_ROUTE}`;
  }
}
