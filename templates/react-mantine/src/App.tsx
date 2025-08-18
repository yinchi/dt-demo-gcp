// Import styles of packages that you've installed.
// All packages except `@mantine/hooks` require styles imports
import '@mantine/core/styles.css';

import { MantineProvider, Title } from '@mantine/core';

export default function App() {
  return <MantineProvider>
    <Title order={1}>React+Vite+Mantine Template</Title>
  </MantineProvider>;
}
