import { useSyncExternalStore } from 'react';

const subscribe = () => () => {};

// During server rendering (static web export) the server snapshot is used;
// in the browser the client snapshot is used, without an extra re-render.
export function useClientOnlyValue<S, C>(server: S, client: C): S | C {
  const isClient = useSyncExternalStore(
    subscribe,
    () => true,
    () => false,
  );
  return isClient ? client : server;
}
