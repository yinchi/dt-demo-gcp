// Import styles of packages that you've installed.
// All packages except `@mantine/hooks` require styles imports

import { useEffect, useState } from "react";

import "@mantine/core/styles.css";
import { useForm } from "@mantine/form";
import {
  MantineProvider,
  AppShell,
  Group,
  Stack,
  Title,
  Text,
  TextInput,
  PasswordInput,
  Button,
  Anchor,
} from "@mantine/core";

import { Icon } from "@iconify/react";

interface SuccessPayload {
  access_token: string;
  token_type: string;
}

interface ErrorPayload {
  detail: string;
}

interface ApiResult {
  statusCode: number;
  payload: SuccessPayload | ErrorPayload;
}

const tokenUrl = "https://yc.ngrok.dev/token";
const redirectURL = "https://yc.ngrok.dev/validate";

function copyright() {
  /** Render the copyright notice. */
  const year: number = new Date().getFullYear();
  const left_year: number = 2025;
  const right_segment: string = year > left_year ? `&ndash;${year}` : "";
  return (
    <Text>
      {`© ${left_year.toString()}${right_segment}`}
      Anandarup Mukherjee & Yin-Chi Chan, Institute for Manufacturing,
      University of Cambridge
    </Text>
  );
}

const callTokenApi = async (values: {
  username: string;
  password: string;
}): Promise<ApiResult> => {
  /** Call the token API and return the result.
   *
   * Parameters:
   * - values: The form values from the calling function.
   *
   * Returns: A promise that resolves to the API result
   */

  // extract username and password from $values
  const { username, password } = values;

  // Add a fixed grant_type
  const urlEncodedBody = new URLSearchParams({
    grant_type: "password",
    username: username,
    password: password,
  }).toString();

  try {
    const response = await fetch(tokenUrl, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: urlEncodedBody,
    });

    // If we got a response, return its status code and payload
    const data = (await response.json()) as SuccessPayload | ErrorPayload;

    return {
      statusCode: response.status,
      payload: data,
    };
  } catch (error) {
    // If we could not get a valid response, return a 500 Internal Server Error
    console.error("API call failed:", error);
    return {
      statusCode: 500,
      payload: { detail: "Internal Server Error" },
    };
  }
};

const login = async (
  values: { username: string; password: string },
  setErrMsg: (msg: string) => void,
  setErrMsgDisplay: (display: string) => void,
) => {
  /** Handle the login process when the page form is submitted.
   *
   * Parameters:
   * - values: The submitted form values.
   *
   * Returns: A promise that redirects the user upon successful login or shows an error message
   * upon failure.
   */
  console.log("Logging in with:", values);
  console.log("Token URL:", tokenUrl);

  const result = await callTokenApi(values);
  if (result.statusCode === 200) {
    console.log("Login successful:", result.statusCode, result.payload);
    const oneDayInMilliseconds = 24 * 60 * 60 * 1000;
    const expiryDate = new Date(
      Date.now() + oneDayInMilliseconds,
    ).toUTCString();
    document.cookie = `access_token=${(result.payload as SuccessPayload).access_token}; Path=/; SameSite=Lax; Expires=${expiryDate}`;
    window.location.href = redirectURL;
  } else {
    console.error("Login failed:", result.statusCode, result.payload);
    setErrMsg((result.payload as ErrorPayload).detail);
    setErrMsgDisplay("block");
  }
};

function MyAppHeader() {
  /** Render the header section of the app. */
  return (
    <AppShell.Header miw={1200}>
      <Group
        justify="space-between"
        flex={1}
        h="100%"
        px="md"
        bg="dark"
        c="white"
      >
        <Title order={1}>Hospital DT Demo</Title>
      </Group>
    </AppShell.Header>
  );
}

function MyAppFooter() {
  /** Render the footer section of the app. */
  return (
    <AppShell.Footer miw={1200} bg={"dark"} c="white">
      <Group justify="space-between" flex={1} h="100%" px="sm" pt={10} pb={5}>
        {copyright()}
        <Anchor href="https://github.com/yinchi/dt-demo-gcp" target="_blank">
          <Icon icon="octicon:mark-github-16" />
          &nbsp;GitHub
        </Anchor>
      </Group>
    </AppShell.Footer>
  );
}

export default function App() {
  const [errMsg, setErrMsg] = useState("");
  const [errMsgDisplay, setErrMsgDisplay] = useState("none");

  // Define the form for user login
  const form = useForm({
    mode: "uncontrolled",
    initialValues: {
      username: "",
      password: "",
    },
    validate: {
      username: (value) => (value ? null : "Username is required"),
      password: (value) => (value ? null : "Password is required"),
    },
  });

  // Define callbacks that run on page load
  useEffect(() => {
    /** Fetch the error field from the URL query fragment and use it to set the
     * error message state. */
    const urlParams = new URLSearchParams(window.location.search.substring(1));
    const error = urlParams.get("error");
    console.log("Error from URL:", error);
    if (error) {
      const theErrorMsg =
        error == "expired_token"
          ? "User access token expired"
          : error == "missing_token"
            ? "User is not authenticated"
            : error == "jwt_error"
              ? "User access token malformed"
              : `Unknown error: ${error}`;
      setErrMsg(theErrorMsg);
      setErrMsgDisplay("block");
    }

    /** Check for a valid access token and redirect if valid. */
    const validateToken = async () => {
      const token = document.cookie
        .split("; ")
        .find((row) => row.startsWith("access_token="))
        ?.split("=")[1];

      if (token) {
        try {
          const response = await fetch(redirectURL, {
            method: "GET",
            headers: {
              Accept: "application/json",
              Cookie: `access_token=${token}`,
            },
          });

          if (response.status === 200) {
            console.log(
              "User already has a valid access token, redirecting...",
            );
            window.location.href = redirectURL;
          } else {
            console.error("Invalid access token, staying on login page.");
          }
        } catch (error) {
          console.error("Token validation failed:", error);
        }
      } else {
        console.log("No existing access token found, staying on login page.");
      }
    };
    validateToken();
  }, []);

  // Return the page layout
  return (
    <MantineProvider>
      <AppShell
        header={{ height: 90 }}
        footer={{ height: 40 }}
        padding="md"
        miw={1200}
      >
        <MyAppHeader />
        <AppShell.Main w={1200 - 35}>
          <form
            onSubmit={form.onSubmit((values) =>
              login(values, setErrMsg, setErrMsgDisplay),
            )}
          >
            <Stack gap="md">
              <Title order={2}>Login</Title>
              <Text c="red" size="lg" style={{ display: errMsgDisplay }}>
                {errMsg}
              </Text>
              <TextInput
                label="Username"
                placeholder="Enter your username"
                size="lg"
                width="100%"
                key={form.key("username")}
                {...form.getInputProps("username")}
              />
              <PasswordInput
                label="Password"
                placeholder="Enter your password"
                size="lg"
                width="100%"
                key={form.key("password")}
                {...form.getInputProps("password")}
              />
              <Button size="lg" c="primary" type="submit">
                Login
              </Button>
            </Stack>
          </form>
        </AppShell.Main>
        <MyAppFooter />
      </AppShell>
    </MantineProvider>
  );
}
