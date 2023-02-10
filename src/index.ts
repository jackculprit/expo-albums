import ExpoAlbumsModule from './ExpoAlbumsModule';

export async function getTheme(): Promise<number> {
  return ExpoAlbumsModule.mainFunction();
}


