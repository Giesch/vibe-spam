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
  if (import.meta.env.MODE === "development") {
    await setupDevFlags();
  }

  const flags = getFlags();

  Elm.Main.init({ flags });
}

/**
 * Gets the server-rendered flags json and parses it.
 *
 * @return {object} Elm app flags
 */
function getFlags() {
  const flagsDiv = document.getElementById(FLAGS_DIV_ID);

  try {
    return JSON.parse(flagsDiv.innerText);
  } catch {
    return {};
  }
}

/**
 * Gets the required elm flags from a json api,
 * and injects them into the document where the backend would normally put them.
 *
 * @return {Promise<void>}
 */
async function setupDevFlags() {
  const flagsJsonString = await getDevFlagsJson();

  const oldFlagsDiv = document.body.querySelector(`#${FLAGS_DIV_ID}`);
  if (oldFlagsDiv) {
    document.body.removeChild(oldFlagsDiv);
  }

  const flagsDiv = document.createElement("div");
  flagsDiv.id = FLAGS_DIV_ID;
  flagsDiv.innerText = flagsJsonString;
  flagsDiv.style = "display: none;";

  document.body.prepend(flagsDiv);
}

async function getDevFlagsJson() {
  const response = await fetch("/api/flags");
  return response.text();
}
