const fs = require("fs");

const jsonEnvironment = fs.readFileSync("environment.json");
const environmentData = JSON.parse(jsonEnvironment);
function getEnvironmentVariables(data) {
  const variablesArary = data.values;
  // with reduce, create a mapper like { {key: { value: value, enabled: enabled } } }
  return variablesArary.reduce((acc, variable) => {
    const key = variable.key;
    const value = variable.value;
    const enabled = variable.enabled;
    acc[key] = { value, enabled };
    return acc;
  }, {});
}

const VARIABLES = getEnvironmentVariables(environmentData);

// Read the JSON file
const jsonData = fs.readFileSync("data.json");
const data = JSON.parse(jsonData);

// Recursive function to generate cURL command for each item
function generateCurl(data) {
  const curls = [];
  const projects = data.item;

  for (const project of projects) {
    const requests = project.item;
    for (const request of requests) {
      // Constructing URL
      let urlData = request?.request?.url;
      if (!urlData) {
        continue;
      }
      const url = urlData.raw;

      const method = request.request.method;

      let headers = request.request.header.map(
        (header) => `\n-H "${header.key}: ${header.value}"`,
      );

      // add bearer token to headers
      let auth = request.request.auth;
      if (auth) {
        if (auth.type === "bearer") {
          headers.push(`\n-H "Authorization: Bearer ${auth.bearer[0].value}"`);
        }
        if (auth.type === "basic") {
          headers.push(`\n-H "Authorization: Basic ${auth.basic[0].value}"`);
        }
      }
      headers = headers.join(" ");

      // Constructing body
      let body = "";
      if (request.request && request.request.body && request.request.body.raw) {
        body += `\n--data-raw '${request.request.body.raw}' `;
      }

      // Constructing cURL command
      // const curlCommand = `curl -X ${method} ${headers} ${body} ${url}`;
      const curlCommand = `curl --location --request ${method} '${url}' ${headers} ${body}`;

      // Injecting variables into the cURL command
      curls.push({
        curl: injectVariables(curlCommand, VARIABLES),
        name: request.name,
      });
    }
  }

  return curls;
}

// Function to inject variables into the curlCommand string
function injectVariables(command, variables) {
  // Regular expression to match variable placeholders like {{variable}}
  const regex = /\{\{(.*?)\}\}/g;

  // Replace each variable placeholder in the command string with its corresponding value
  const updatedCommand = command.replace(regex, (_, variableName) => {
    if (variables[variableName] && variables[variableName].enabled) {
      return variables[variableName].value;
    } else {
      return ""; // Replace with an empty string if the variable is not enabled or not found
    }
  });

  return updatedCommand;
}

// Start generating cURL commands
const CURL_DATA = generateCurl(data);

// Write the cURL commands to a file separated by blank lines
// add # name before each curl
const curlCommands = CURL_DATA.map(
  (curl) => `# ${curl.name}\n${curl.curl}`,
).join("\n\n");

fs.writeFileSync("curl_commands.sh", curlCommands);
