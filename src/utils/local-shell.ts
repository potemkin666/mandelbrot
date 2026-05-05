export type LocalShellState = 'starting' | 'ready' | 'error';

export const LOCAL_SHELL_LABELS: Record<LocalShellState, string> = {
  starting: 'Booting local tide',
  ready: 'Local waters steady',
  error: 'Startup snag',
};
