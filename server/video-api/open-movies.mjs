// Original soundtracks retained. Licenses/credits refer to the original films.
export const openMovies = [
  {id: 'BigBuckBunny_124', file: 'Content/big_buck_bunny_720p_surround.mp4',
    title: 'Big Buck Bunny', author: 'Blender Foundation',
    projectUrl: 'https://peach.blender.org/', licenseUrl: 'https://creativecommons.org/licenses/by/3.0/',
    width: 640, height: 360, duration: 596.48},
  {id: 'Sintel', file: 'sintel-2048-stereo_512kb.mp4', title: 'Sintel',
    author: 'Blender Foundation', projectUrl: 'https://durian.blender.org/about/',
    licenseUrl: 'https://creativecommons.org/licenses/by/3.0/', width: 564, height: 240, duration: 888.064},
  {id: 'ElephantsDream', file: 'ed_1024_512kb.mp4', title: 'Elephants Dream',
    author: 'Blender Foundation / Netherlands Media Art Institute',
    projectUrl: 'https://orange.blender.org/press/', licenseUrl: 'https://creativecommons.org/licenses/by/2.5/',
    width: 426, height: 240, duration: 653.792},
  {id: 'CaminandesLlamigos', file: 'Caminandes_ Llamigos-1080p.mp4',
    title: 'Caminandes 3: Llamigos', author: 'Blender Foundation',
    projectUrl: 'https://studio.blender.org/films/caminandes-3/',
    licenseUrl: 'https://creativecommons.org/licenses/by/4.0/', width: 1920, height: 1080, duration: 150.101},
];

export async function loadOpenMovies(fetcher = fetch) {
  const movies = await Promise.all(openMovies.map(async movie => {
    try {
      const response = await fetcher(`https://archive.org/metadata/${movie.id}`,
        {signal: AbortSignal.timeout(12000)});
      if (!response.ok) return null;
      const data = await response.json();
      if (!data.files?.some(file => file.name === movie.file)) return null;
      return {id: `open-${movie.id}`, provider: 'Blender Open Movies', title: movie.title,
        author: movie.author, projectUrl: movie.projectUrl, licenseUrl: movie.licenseUrl,
        sourceUrl: `https://archive.org/details/${movie.id}`,
        url: `https://archive.org/download/${movie.id}/${movie.file.split('/').map(encodeURIComponent).join('/')}`,
        width: movie.width, height: movie.height, duration: movie.duration,
        hasAudio: true, audiblePreview: true, startAtSeconds: 30};
    } catch (_) { return null; }
  }));
  return movies.filter(Boolean);
}
