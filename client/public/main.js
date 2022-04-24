import { Elm } from "../src/Main.elm";

// The id of an element containing json Elm flags
// NOTE this id must match the one used in the root /templates/index.html
const FLAGS_DIV_ID = "elm-flags-json";

/**
 * Starts the Elm app with the server-rendered flags (ie session data)
 *
 * @return {object} app - the Elm application
 */
export async function initWithFlags() {
  const flags = await getFlagsForEnv();

  Elm.Main.init({ flags });
}

/**
 * Gets the flags from either server-rendered
 * html (in prod) or json endpoint (in local dev).
 *
 * @return {object} Elm app flags
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
