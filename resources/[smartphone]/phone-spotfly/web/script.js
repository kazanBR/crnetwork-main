const API = "https://phone-spotfly";
const fallbackCover = "assets/icon.svg";
const SEARCH_API = "https://itunes.apple.com/search";

let tracks = [];
let onlineResults = [];
let likes = new Set();
let playlists = [];
let playlistTracks = new Map();
let recent = [];
let queue = [];
let currentIndex = -1;
let currentView = "all";
let activePlaylistId = null;
let selectedTrackId = null;
let shuffle = false;
let repeatMode = "off";
let saveTimer = null;
let searchTimer = null;
let isSearching = false;
let searchProvider = "youtube";
let currentTrack = null;
let playerPlaying = false;
let outputTarget = "phone";

const audio = document.getElementById("audio");

function post(event, data = {}) {
  return new Promise((resolve) => {
    $.post(`${API}/${event}`, JSON.stringify(data), resolve).fail(() => resolve(false));
  });
}

function searchCatalog(term) {
  return new Promise((resolve) => {
    $.ajax({
      url: SEARCH_API,
      dataType: "json",
      data: {
        term,
        media: "music",
        entity: "song",
        limit: 25,
        country: "BR",
      },
      success: (data) => resolve(data && data.results ? data.results : []),
      error: () => resolve([]),
    });
  });
}

function normalizeCatalogTrack(item) {
  const artwork = item.artworkUrl100 ? item.artworkUrl100.replace("100x100bb", "600x600bb") : fallbackCover;

  return {
    id: `catalog-${item.trackId}`,
    external: true,
    title: item.trackName || "Musica desconhecida",
    artist: item.artistName || "Artista desconhecido",
    album: item.collectionName || "",
    genre: item.primaryGenreName || "",
    cover: artwork,
    url: item.previewUrl || "",
    duration: Math.round((item.trackTimeMillis || 0) / 1000),
  };
}

function getVideoId(track) {
  return track && (track.videoId || track.video_id || "");
}

function byId(id) {
  const all = [...tracks, ...onlineResults];
  return all.find((track) => String(track.id) === String(id));
}

function image(track) {
  return track && track.cover ? track.cover : fallbackCover;
}

function escapeHtml(value) {
  return String(value || "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function formatTime(value) {
  value = Number.isFinite(value) ? Math.max(0, value) : 0;
  const minutes = Math.floor(value / 60);
  const seconds = Math.floor(value % 60).toString().padStart(2, "0");
  return `${minutes}:${seconds}`;
}

function openScreen(id) {
  $(".screen").removeClass("active");
  $(`#${id}`).addClass("active").scrollTop(0);
}

async function ensureTrackSaved(track) {
  if (!track || !track.external) {
    return track;
  }

  const created = await post("addTrack", {
    title: track.title,
    artist: track.artist,
    album: track.album,
    genre: track.genre,
    url: track.url,
    cover: track.cover,
    duration: track.duration,
    source: track.youtube || track.source === "youtube" ? "youtube" : "audio",
    videoId: getVideoId(track),
  });

  if (!created || !created.id) {
    return track;
  }

  const previousId = track.id;
  Object.assign(track, created, { external: false });

  if (!tracks.some((item) => Number(item.id) === Number(created.id))) {
    tracks.unshift(created);
  }

  onlineResults = onlineResults.map((item) => String(item.id) === String(previousId) ? track : item);
  queue = queue.map((item) => String(item.id) === String(previousId) ? track : item);

  return track;
}

function saveStateSoon() {
  clearTimeout(saveTimer);
  saveTimer = setTimeout(() => {
    const current = queue[currentIndex];
    post("saveState", {
      trackId: current && !current.external ? current.id : null,
      volume: Number($("#volume").val()),
      shuffle,
      repeatMode,
    });
  }, 300);
}

function makeQueue(list, startId) {
  queue = list.filter((track) => track && track.url);
  currentIndex = queue.findIndex((track) => String(track.id) === String(startId));

  if (currentIndex < 0 && queue.length) {
    currentIndex = 0;
  }
}

async function playTrack(track, list = null) {
  if (!track || !track.url) {
    return;
  }

  track = await ensureTrackSaved(track);

  if (list) {
    const normalizedList = list.map((item) => String(item.id) === String(track.id) ? track : item);
    makeQueue(normalizedList, track.id);
  } else if (currentIndex < 0 || !queue.length) {
    makeQueue(getVisibleTracks(), track.id);
  } else {
    currentIndex = queue.findIndex((item) => String(item.id) === String(track.id));
  }

  currentTrack = track;
  playerPlaying = true;
  $("#play i").attr("class", "fa-solid fa-pause");

  const response = await post("spotflyPlayer", {
    action: "play",
    track,
    volume: Number($("#volume").val()),
  });

  if (response && response.output) {
    outputTarget = response.output;
    updateOutputButton();
  }

  updatePlayer(track);

  if (!track.external) {
    post("addRecent", { trackId: track.id });
    recent = [track.id, ...recent.filter((id) => Number(id) !== Number(track.id))].slice(0, 20);
  }

  saveStateSoon();
}

async function pausePlayer() {
  await post("spotflyPlayer", { action: "pause" });
  playerPlaying = false;
  $("#play i").attr("class", "fa-solid fa-play");
}

async function resumePlayer() {
  if (!currentTrack) {
    const visible = getVisibleTracks();
    const first = visible[0] || tracks[0];
    if (first) await playTrack(first, visible.length ? visible : tracks);
    return;
  }

  await post("spotflyPlayer", { action: "resume" });
  playerPlaying = true;
  $("#play i").attr("class", "fa-solid fa-pause");
}

function updateOutputButton() {
  $("#output").toggleClass("enabled", outputTarget === "vehicle");
  $("#featured-label").text(outputTarget === "vehicle" ? "Tocando no veiculo" : "Tocando no celular");
}

function updatePlayer(track) {
  $("#player-cover").attr("src", image(track));
  $("#player-title").text(track ? track.title : "Spotfy");
  $("#player-artist").text(track ? track.artist : "Nenhuma musica tocando");
  $("#progress").val(0).attr("data-duration", track && track.duration ? track.duration : 0);
  $("#current-time").text("0:00");
  $("#duration").text(track && track.duration ? formatTime(track.duration) : "0:00");
  $("#featured-cover").attr("src", image(track));
  $("#featured-title").text(track ? track.title : "Escolha uma faixa");
  $("#featured-artist").text(track ? track.artist : "Digite uma musica para buscar online");
}

async function nextTrack() {
  if (!queue.length) return;

  if (repeatMode === "one") {
    await playTrack(queue[currentIndex]);
    return;
  }

  if (shuffle && queue.length > 1) {
    let next = currentIndex;
    while (next === currentIndex) {
      next = Math.floor(Math.random() * queue.length);
    }
    currentIndex = next;
  } else if (currentIndex < queue.length - 1) {
    currentIndex += 1;
  } else if (repeatMode === "all") {
    currentIndex = 0;
  } else {
    $("#play i").attr("class", "fa-solid fa-play");
    return;
  }

  await playTrack(queue[currentIndex]);
}

async function previousTrack() {
  if (!queue.length) return;

  currentIndex = currentIndex > 0 ? currentIndex - 1 : queue.length - 1;
  await playTrack(queue[currentIndex]);
}

function hasSearchTerm() {
  return currentView === "all" && $("#search").val().trim().length >= 2;
}

function getVisibleTracks() {
  const term = $("#search").val().toLowerCase().trim();

  if (hasSearchTerm()) {
    return onlineResults;
  }

  let list = tracks;

  if (currentView === "liked") {
    list = tracks.filter((track) => likes.has(Number(track.id)));
  } else if (currentView === "recent") {
    list = recent.map(byId).filter(Boolean);
  } else if (currentView === "playlist" && activePlaylistId) {
    const ids = playlistTracks.get(Number(activePlaylistId)) || [];
    list = ids.map(byId).filter(Boolean);
  }

  if (term) {
    list = list.filter((track) => {
      return [track.title, track.artist, track.album, track.genre].join(" ").toLowerCase().includes(term);
    });
  }

  return list;
}

function renderTracks(target = "#track-list", list = getVisibleTracks()) {
  const wrapper = $(target);
  wrapper.empty();
  $("#track-count").text(isSearching ? "..." : list.length);

  if (isSearching) {
    wrapper.append(`<div class="empty"><i class="fa-solid fa-compact-disc fa-spin"></i><span>Procurando musicas...</span></div>`);
    return;
  }

  if (!list.length) {
    const message = hasSearchTerm() ? "Nenhuma musica encontrada nessa busca." : "Nada por aqui ainda.";
    wrapper.append(`<div class="empty"><i class="fa-solid fa-music"></i><span>${message}</span></div>`);
    return;
  }

  list.forEach((track) => {
    const liked = !track.external && likes.has(Number(track.id));
    wrapper.append(`
      <article class="track" data-id="${escapeHtml(track.id)}">
        <img src="${escapeHtml(track.cover || fallbackCover)}" alt="Capa" />
        <div class="track-info">
          <strong>${escapeHtml(track.title)}</strong>
          <span>${escapeHtml(track.artist)}${track.album ? ` - ${escapeHtml(track.album)}` : ""}</span>
          ${track.external ? `<em>${track.youtube || track.source === "youtube" ? "YouTube" : "Resultado online - preview"}</em>` : ``}
        </div>
        <button type="button" class="like-btn ${liked ? "liked" : ""}" data-id="${escapeHtml(track.id)}"><i class="${liked ? "fa-solid" : "fa-regular"} fa-heart"></i></button>
        <button type="button" class="menu-btn" data-id="${escapeHtml(track.id)}"><i class="fa-solid fa-ellipsis"></i></button>
      </article>
    `);
  });
}

function renderPlaylists() {
  const wrapper = $("#playlist-list");
  wrapper.empty();

  if (!playlists.length) {
    wrapper.append(`<div class="empty small">Crie sua primeira playlist.</div>`);
    return;
  }

  playlists.forEach((playlist) => {
    const ids = playlistTracks.get(Number(playlist.id)) || [];
    wrapper.append(`
      <button type="button" class="playlist-card" data-id="${playlist.id}">
        <img src="${escapeHtml(playlist.cover || fallbackCover)}" alt="Playlist" />
        <div><strong>${escapeHtml(playlist.name)}</strong><span>${ids.length} musicas</span></div>
      </button>
    `);
  });
}

function renderMenuPlaylists(trackId) {
  const wrapper = $("#menu-playlists");
  wrapper.empty();

  if (!playlists.length) {
    wrapper.append(`<span class="hint">Crie uma playlist para salvar esta musica.</span>`);
    return;
  }

  playlists.forEach((playlist) => {
    const ids = playlistTracks.get(Number(playlist.id)) || [];
    const hasTrack = ids.some((id) => Number(id) === Number(trackId));
    wrapper.append(`
      <button type="button" class="playlist-toggle" data-playlist="${playlist.id}" data-track="${trackId}">
        <i class="fa-solid ${hasTrack ? "fa-check" : "fa-plus"}"></i>${hasTrack ? "Remover de" : "Adicionar em"} ${escapeHtml(playlist.name)}
      </button>
    `);
  });
}

function refresh() {
  const searching = hasSearchTerm();
  $("#playlist-panel").toggleClass("hidden", currentView !== "playlists");
  $("#track-section-title").text(searching ? (searchProvider === "youtube" ? "Resultados do YouTube" : "Resultados online") : currentView === "liked" ? "Curtidas" : currentView === "recent" ? "Recentes" : "Musicas");
  renderPlaylists();
  renderTracks();
}

async function runOnlineSearch() {
  const term = $("#search").val().trim();

  if (!hasSearchTerm()) {
    onlineResults = [];
    isSearching = false;
    refresh();
    return;
  }

  isSearching = true;
  refresh();

  searchProvider = "youtube";
  let response = await post("searchYouTube", { term });
  let results = response && response.ok ? response.results : [];

  if (!results.length) {
    searchProvider = "preview";
    results = await searchCatalog(term);
  }

  if ($("#search").val().trim() !== term) {
    return;
  }

  onlineResults = results
    .map((item) => item.youtube ? item : normalizeCatalogTrack(item))
    .filter((track) => track.url)
    .filter((track, index, list) => list.findIndex((item) => item.id === track.id) === index);

  isSearching = false;
  refresh();
}

async function loadData() {
  const data = await post("getData");

  tracks = data.tracks || [];
  likes = new Set((data.likes || []).map((item) => Number(item.track_id)));
  playlists = data.playlists || [];
  playlistTracks = new Map();
  recent = (data.recent || []).map((item) => Number(item.track_id));

  (data.playlistTracks || []).forEach((item) => {
    const playlistId = Number(item.playlist_id);
    const trackId = Number(item.track_id);
    const ids = playlistTracks.get(playlistId) || [];
    ids.push(trackId);
    playlistTracks.set(playlistId, ids);
  });

  if (data.state) {
    shuffle = Number(data.state.shuffle) === 1;
    repeatMode = data.state.repeat_mode || "off";
    $("#volume").val(data.state.volume || 80);
    audio.volume = Number($("#volume").val()) / 100;
    $("#shuffle").toggleClass("enabled", shuffle);
    $("#repeat").toggleClass("enabled", repeatMode !== "off").attr("data-mode", repeatMode);
    const savedTrack = byId(data.state.track_id);
    if (savedTrack) updatePlayer(savedTrack);
  }

  refresh();
}

$(document).ready(() => {
  loadData();

  $("#search").on("input", () => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(runOnlineSearch, 450);
    refresh();
  });

  $(document).on("click", ".tab", function () {
    $(".tab").removeClass("active");
    $(this).addClass("active");
    currentView = $(this).data("view");
    activePlaylistId = null;
    if (currentView !== "all") {
      onlineResults = [];
      isSearching = false;
    }
    refresh();
  });

  $(document).on("click", ".track", async function () {
    const track = byId($(this).data("id"));
    await playTrack(track, getVisibleTracks());
  });

  $(document).on("click", ".like-btn", async function (event) {
    event.stopPropagation();
    let track = byId($(this).data("id"));
    track = await ensureTrackSaved(track);
    if (!track || track.external) return;

    const id = Number(track.id);
    const result = await post("toggleLike", { trackId: id });
    if (result && result.liked) likes.add(id); else likes.delete(id);
    refresh();
  });

  $(document).on("click", ".menu-btn", async function (event) {
    event.stopPropagation();
    let track = byId($(this).data("id"));
    track = await ensureTrackSaved(track);
    if (!track || track.external) return;

    selectedTrackId = Number(track.id);
    $("#menu-track-title").text(track.title || "Musica");
    renderMenuPlaylists(selectedTrackId);
    $("#track-menu-modal").removeClass("hidden");
    refresh();
  });

  $("#menu-like").on("click", async () => {
    if (!selectedTrackId) return;
    const result = await post("toggleLike", { trackId: selectedTrackId });
    if (result && result.liked) likes.add(selectedTrackId); else likes.delete(selectedTrackId);
    refresh();
    renderMenuPlaylists(selectedTrackId);
  });

  $(document).on("click", ".playlist-toggle", async function () {
    const playlistId = Number($(this).data("playlist"));
    const trackId = Number($(this).data("track"));
    const ids = playlistTracks.get(playlistId) || [];
    const exists = ids.some((id) => Number(id) === trackId);

    if (exists) {
      await post("removeFromPlaylist", { playlistId, trackId });
      playlistTracks.set(playlistId, ids.filter((id) => Number(id) !== trackId));
    } else {
      await post("addToPlaylist", { playlistId, trackId });
      playlistTracks.set(playlistId, [...ids, trackId]);
    }

    renderMenuPlaylists(trackId);
    refresh();
  });

  $("#close-track-menu").on("click", () => $("#track-menu-modal").addClass("hidden"));
  $("#open-add-track").on("click", () => openScreen("add-screen"));
  $(".back-btn").on("click", function () { openScreen($(this).data("back")); });

  $("#new-playlist").on("click", () => $("#playlist-modal").removeClass("hidden"));
  $("#cancel-playlist").on("click", () => $("#playlist-modal").addClass("hidden"));

  $("#save-playlist").on("click", async () => {
    const name = $("#playlist-name").val().trim();
    const cover = $("#playlist-cover").val().trim();
    if (!name) return;
    const created = await post("createPlaylist", { name, cover });
    if (created && created.id) {
      playlists.unshift(created);
      playlistTracks.set(Number(created.id), []);
      $("#playlist-name, #playlist-cover").val("");
      $("#playlist-modal").addClass("hidden");
      currentView = "playlists";
      $(".tab").removeClass("active");
      $('.tab[data-view="playlists"]').addClass("active");
      refresh();
    }
  });

  $(document).on("click", ".playlist-card", function () {
    activePlaylistId = Number($(this).data("id"));
    currentView = "playlist";
    const playlist = playlists.find((item) => Number(item.id) === activePlaylistId);
    const list = (playlistTracks.get(activePlaylistId) || []).map(byId).filter(Boolean);
    $("#playlist-title").text(playlist ? playlist.name : "Playlist");
    renderTracks("#playlist-track-list", list);
    openScreen("playlist-screen");
  });

  $("#delete-playlist").on("click", async () => {
    if (!activePlaylistId) return;
    const ok = await post("deletePlaylist", { playlistId: activePlaylistId });
    if (ok) {
      playlists = playlists.filter((item) => Number(item.id) !== activePlaylistId);
      playlistTracks.delete(activePlaylistId);
      activePlaylistId = null;
      currentView = "playlists";
      openScreen("home-screen");
      refresh();
    }
  });

  $("#track-form").on("submit", async function (event) {
    event.preventDefault();
    const created = await post("addTrack", {
      title: $("#track-title").val(),
      artist: $("#track-artist").val(),
      album: $("#track-album").val(),
      genre: $("#track-genre").val(),
      url: $("#track-url").val(),
      cover: $("#track-cover").val(),
    });

    if (created && created.id) {
      tracks.unshift(created);
      this.reset();
      currentView = "all";
      $(".tab").removeClass("active");
      $('.tab[data-view="all"]').addClass("active");
      openScreen("home-screen");
      refresh();
    }
  });

  $("#play").on("click", async () => {
    if (playerPlaying) {
      await pausePlayer();
    } else {
      await resumePlayer();
    }
  });

  $("#next").on("click", nextTrack);
  $("#prev").on("click", previousTrack);

  $("#shuffle").on("click", function () {
    shuffle = !shuffle;
    $(this).toggleClass("enabled", shuffle);
    saveStateSoon();
  });

  $("#repeat").on("click", function () {
    repeatMode = repeatMode === "off" ? "all" : repeatMode === "all" ? "one" : "off";
    $(this).toggleClass("enabled", repeatMode !== "off").attr("data-mode", repeatMode);
    saveStateSoon();
  });

  $("#volume").on("input", function () {
    post("spotflyPlayer", { action: "volume", volume: Number($(this).val()) });
    saveStateSoon();
  });

  $("#progress").on("input", function () {
    const durationText = Number($("#progress").attr("data-duration") || 0);
    if (durationText > 0) {
      post("spotflyPlayer", {
        action: "seek",
        timestamp: (Number($(this).val()) / 100) * durationText,
      });
    }
  });

  setInterval(async () => {
    const status = await post("spotflyStatus", {});
    if (!status) return;

    outputTarget = status.output || outputTarget;
    playerPlaying = !!status.playing;
    updateOutputButton();

    if (status.duration && status.duration > 0) {
      $("#progress").attr("data-duration", status.duration).val((status.timestamp / status.duration) * 100);
      $("#duration").text(formatTime(status.duration));
    }

    $("#current-time").text(formatTime(status.timestamp || 0));
    $("#play i").attr("class", playerPlaying ? "fa-solid fa-pause" : "fa-solid fa-play");
  }, 1000);

  $("#output").on("click", async () => {
    const targets = await post("spotflyTargets", {});
    outputTarget = targets.output || outputTarget;
    updateOutputButton();

    $(".output-choice").removeClass("active");
    $(`.output-choice[data-output="${outputTarget}"]`).addClass("active");
    $('.output-choice[data-output="vehicle"]').prop("disabled", !targets.vehicle);

    let hint = "Celular: som apenas para voce.";
    if (targets.vehicle) {
      hint = "Veiculo: som sai no carro e acompanha ele.";
    } else if (targets.reason === "blocked_vehicle") {
      hint = "Veiculo indisponivel em motos ou bicicletas.";
    } else {
      hint = "Entre em um carro para usar o som do veiculo.";
    }

    $("#output-hint").text(hint);
    $("#output-modal").removeClass("hidden");
  });

  $("#close-output-menu").on("click", () => $("#output-modal").addClass("hidden"));

  $(document).on("click", ".output-choice", async function () {
    const output = $(this).data("output");
    const response = await post("spotflySetOutput", { output });

    if (response && response.ok) {
      outputTarget = response.output;
      updateOutputButton();
      $("#output-modal").addClass("hidden");
      return;
    }

    if (response && response.reason === "blocked_vehicle") {
      $("#output-hint").text("Nao da para usar Bluetooth em motos ou bicicletas.");
    } else {
      $("#output-hint").text("Entre em um carro para tocar no veiculo.");
    }
  });

  window.addEventListener("message", (event) => {
    const data = event.data || {};
    if (data.action === "spotflyOutputChanged") {
      outputTarget = data.output || "phone";
      updateOutputButton();

      if (data.paused) {
        playerPlaying = false;
        $("#play i").attr("class", "fa-solid fa-play");

        if (data.reason === "vehicle_taken") {
          $("#player-artist").text("Outro celular conectou neste veiculo");
        } else if (data.reason === "vehicle_gone") {
          $("#player-artist").text("Veiculo desconectado");
        }
      }
    }

    if (data.action === "spotflyPlaybackEnded") {
      playerPlaying = false;
      $("#play i").attr("class", "fa-solid fa-play");
      nextTrack();
    }
  });

  audio.addEventListener("ended", nextTrack);
});
