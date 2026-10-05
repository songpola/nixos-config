# Setup: qBittorrent

https://trash-guides.info/Downloaders/qBittorrent/Basic-Setup/

## qui (autobrr/qui)

- **Files** (File Management)
  - Automatic Torrent Management: **ENABLED**
  - Relocate on Category Change: **ENABLED**
  - Relocate on Default Save Path Change: **ENABLED**
  - Relocate on Category Save Path Change: **ENABLED**
  - Default Save Path: (same as `$containerTorrentsDataDir`)
    - For example: `/mnt/starrs-data/torrents` (see the module implementation for the actual value)
    - NOTE: This is **NOT** the path on the host, but the path *inside the container* where qBittorrent will store torrent files and data.
  - Default Content Layout: **Original**
- **Connect** (Connection Settings)
  - Protocol Settings
    - BitTorrent Protocol: **TCP**
- **Category**
  - `radarr`
  - `radarr-anime`

# Setup: Radarr

## 1. Download Clients

- **Category**
  - For Main: `radarr`
  - For Anime: `radarr-anime`
- **Remove Completed**: Disabled

## 2. Media Management

### Movie Naming

> [!NOTE]
> **IMDb vs TMDb?**
> 
> **TMDb** is generally better and more aligned with Radarr for metadata and searching.
> While IMDb is reliable for accuracy, TMDb ensures better matching and integration within Radarr's ecosystem.
> For organizing files, including the `{tmdb-id}` or `{imdb-tt...}` in the folder/file name is recommended,
> with TMDb often preferred for its comprehensive data.

- **Rename Movies**: Enabled
- **Replace Illegal Characters**: Enabled
  - **Colon Replacement**: `Smart Replace`
    ```cs
    // Smart replaces a colon followed by a space with space dash space for a better appearance
    if (namingConfig.ColonReplacementFormat == ColonReplacementFormat.Smart)
    {
        result = result.Replace(": ", " - ");
        result = result.Replace(":", "-");
    }
    ```
- **[Standard Movie Format](https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/#standard-movie-format)**
  - For Main: use [Jellyfin (TMDb)](https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/#jellyfin-tmdb)
    ```
    {Movie CleanTitle} {(Release Year)} [tmdbid-{TmdbId}] - {{Edition Tags}} {[MediaInfo 3D]}{[Custom Formats]}{[Quality Full]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[MediaInfo VideoDynamicRangeType]}{[Mediainfo VideoCodec]}{-Release Group}
    ```
  - For Anime: use [Jellyfin Anime (TMDb)](https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/#jellyfin-anime-tmdb)
    ```
    {Movie CleanTitle} {(Release Year)} [tmdbid-{TmdbId}] - {{Edition Tags}} {[MediaInfo 3D]}{[Custom Formats]}{[Quality Full]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{MediaInfo AudioLanguages}{[MediaInfo VideoDynamicRangeType]}[{Mediainfo VideoCodec }{MediaInfo VideoBitDepth}bit]{-Release Group}
    ```
- **[Movie Folder Format](https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/#movie-folder-format)**
  - Use [Jellyfin Folder TMDb](https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/#jellyfin-folder-tmdb)
    ```
    {Movie CleanTitle} ({Release Year}) [tmdbid-{TmdbId}]
    ```

### Importing

- **Use Hardlinks instead of Copy**: Enabled

### File Management

- **Unmonitor Deleted Movies**: Enabled
- **Propers and Repacks**: `Do Not Prefer`
  - **NOTE:** Use the *Repack/Proper* Custom Format instead, according to [this guide](https://trash-guides.info/Radarr/Radarr-collection-of-custom-formats/). This way you make sure the Custom Format scoring and preferences will be fully utilized.
- **Analyze video files**: Enabled

### Root Folders

> [!NOTE]
> Your download client downloads to a *download* folder and Radarr imports it to your *media* folder (final destination) that your media server uses.

> [!CAUTION]
> Your *download* folder and *media* (library / root) folder **CANNOT** be the same location

- Let `$baseDataDir` =  `/mnt/starrs-data`:
  - **Mount the the host's data directory to this path in the Radarr container**
  - For example: the Docker volume mapping would be `-v /path/to/host/starrs-data:/mnt/starrs-data`
- Let `$mediaDataDir` = `$baseDataDir/media`:
  - Use the ***subdirectory*** of this path as the Root Folder in Radarr for your media library.
    - For example: `$mediaDataDir/movies`, `$mediaDataDir/movies-anime`, `$mediaDataDir/tv`, etc.
    - This is to separate different types of media (e.g. movies, tv shows, anime) for their respective media managers (Radarr, Sonarr, etc.)
  - For Main: the **Root Folder** for Radarr (`movies`) would be `$mediaDataDir/movies` (e.g. `/mnt/starrs-data/media/movies`)
  - For Anime: the **Root Folder** for Radarr (`movies-anime`) would be `$mediaDataDir/movies-anime` (e.g. `/mnt/starrs-data/media/movies-anime`)

> [!TIP]
> See [this](https://trash-guides.info/File-and-Folder-Structure/How-to-set-up/Dockstarter/#radarr) as an example

## 3. Quality

## 4. Custom Formats

[How to import Custom Formats](https://trash-guides.info/Radarr/Radarr-import-custom-formats/)

## 5. Profiles
