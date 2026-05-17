Config = {}

Config.App = {
    name = 'Spotfy',
    description = 'Musicas, playlists e favoritos',
    developer = 'zVegas',
    defaultApp = true,
    size = 48200
}

Config.YouTube = {
    enabled = true,
    -- Coloque aqui sua chave da YouTube Data API v3.
    -- Exemplo: apiKey = 'AIza...'
    apiKey = 'AIzaSyBzt3cUJ-sEfBlcy4SA3QUka8W6MWzWxWY',
    maxResults = 10,
    regionCode = 'BR'
}

-- Use direct audio URLs. MP3 files and public radio streams work best in FiveM NUI.
Config.DefaultTracks = {
    {
        title = 'Midnight Drive',
        artist = 'Spotfy Sessions',
        album = 'City Nights',
        cover = 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&q=80',
        url = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        duration = 372,
        genre = 'Electronic'
    },
    {
        title = 'Golden Avenue',
        artist = 'Spotfy Sessions',
        album = 'Downtown',
        cover = 'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=800&q=80',
        url = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        duration = 333,
        genre = 'Pop'
    },
    {
        title = 'Late Night Radio',
        artist = 'Spotfy Sessions',
        album = 'After Hours',
        cover = 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800&q=80',
        url = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        duration = 344,
        genre = 'Chill'
    },
    {
        title = 'Neon Skyline',
        artist = 'Spotfy Sessions',
        album = 'Drive FM',
        cover = 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=800&q=80',
        url = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        duration = 305,
        genre = 'House'
    }
}
