var Perm = false;
$(document).ready(() => {
  const RESOURCE = (typeof GetParentResourceName === "function")
    ? GetParentResourceName()
    : "phone-weazel";

  var News = [];

  const form = $("#form");
  var isValid;

  function checkFormValidity() {
    const publishButton = $("#publish");
    isValid = form[0].checkValidity();

    if (isValid) {
      publishButton.css({ opacity: "1.0", "pointer-events": "auto" });
    } else {
      publishButton.css({ opacity: "0.5", "pointer-events": "none" });
    }
  }

  form.on("input", checkFormValidity);

  checkFormValidity();

  const reloadMainPage = () => {
    $("#create").hide();
    $("#post").hide();
      $("#main").show();

      $.post(`https://${RESOURCE}/getNews`, [], (data) => {
        News = data;

      loadWeezel();
    });
  };

  const loadWeezel = () => {
    $("#list-weazel").html("");

    News.map((item, index) => {
      const html = `
        <li>
          <main id="news" data-index="${index}">
            <section>
              <h2>${item.title}</h2>
              <p>${item.description}</p>
              
              <span>${item.category || "Notícia"} • ${item.day} <b>(${item.author})</b></span>
            </section>
            <img src="${item.img}" />
          </main>
          <footer>
            <div id="main-infos" title="Visualizações">
              <i class="fa-regular fa-eye"></i><span>${
                item.visualizations
              }</span>
            </div>
            ${item.featured ? `<div class="news-badge">Destaque</div>` : ``}
            ${
              (Perm &&
                `
              <div id="main-edits">
                <i id="edit-news" data-index="${index}" class="fa-solid fa-pen" title="Editar">Editar</i>
                <i id="delete-news" data-index="${index}" class="fa-solid fa-trash" title="Excluir">Excluir</i>
              </div>
            `) ||
              ``
            }
          </footer>
        </li>
      `;

      $("#list-weazel").append(html);
    });
  };

  $.post(`https://${RESOURCE}/hasPermission`, [], (data) => {
    if (data) {
      console.log(data);
      Perm = true;
      $("#main-create").show();
    }

    setTimeout(() => {
      reloadMainPage();
    }, 500);
  });

  $(document).on("click", "#main-create", function () {
    $("#main").hide();
    $("#create").show();
  });

  $(document).on("click", "#publish", function () {
    const inputs = ["title", "author", "category", "desc", "video", "photo"];
    const values = inputs.reduce((acc, input) => {
      acc[input] = $(`#input-${input}`).val();
      return acc;
    }, {});

    const { title, author, category, desc, video, photo } = values;
    const featured = $("#input-featured").is(":checked");

    if (
      title.length !== 0 &&
      author.length !== 0 &&
      desc.length !== 0 &&
      photo.length !== 0
    ) {
      $.post(
        `https://${RESOURCE}/createPost`,
        JSON.stringify({
          title: title,
          author: author,
          category: category,
          featured: featured,
          description: desc,
          video: video,
          photo: photo,
        }),
        (data) => {
          if (data) {
            setTimeout(() => {
              reloadMainPage();
            }, 500);
          }
        }
      );
    }
  });

  $(document).on("click", "#create-back", function () {
    $("#main").show();
    $("#create").hide();

    $("#input-title").val("");
    $("#input-author").val("");
    $("#input-category").val("Notícia");
    $("#input-desc").val("");
    $("#input-video").val("");
    $("#input-photo").val("");
    $("#input-featured").prop("checked", false);
  });

  const getYoutubeId = (link) => {
    var video_id = link.split("v=")[1];
    var ampersandPosition = video_id.indexOf("&");
    if (ampersandPosition != -1) {
      video_id = video_id.substring(0, ampersandPosition);
    }
    return video_id;
  };

  $(document).on("click", "#news", function () {
    const index = $(this).data("index");
    const data = News[index];

    $("#main").hide();
    $("#post").show();

    $(".post").html(`
      <strong id="weazel-title">${data.title}</strong>
      <span>${data.category || "Notícia"} • ${
        data.day
      } <b id="post-author">(${data.author})</b></span>
      ${data.featured ? `<small class="news-badge news-badge-inline">Destaque</small>` : ``}
      <p>${data.description}</p>

      ${
        (data.img !== "" &&
          `
        <img id="post-image" title="Imagem da notícia" src="${data.img}" />
      `) ||
        ""
      }

      ${
        (data.video !== "" &&
          `
        <iframe title="Vídeo da notícia" height="315" src="https://www.youtube.com/embed/${getYoutubeId(
          data.video
        )}?controls=1" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope"></iframe>
      `) ||
        ""
      }
    `);

    $.post(
      `https://${RESOURCE}/setVisualization`,
      JSON.stringify({
        id: index + 1,
      })
    );
  });

  $(document).on("click", "#post-back", function () {
    $("#post").hide();
    $(".post").html("");

    reloadMainPage();
  });

  $(document).on("click", "#edit-news", function () {
    const index = $(this).data("index");
    const data = News[index];

    $("#main").hide();

    $("#create").show();

    $("#form").html(`
      <div class="input-wrapper">
        <label for="input-title">Título</label>
        <input id="input-title" type="text" required value="${data.title}" />
      </div>

      <div class="input-wrapper">
        <label for="input-author">Autor</label>
        <input id="input-author" type="text" required value="${data.author}" />
      </div>

      <div class="input-wrapper">
        <label for="input-category">Categoria</label>
        <select id="input-category">
          <option value="Notícia" ${((data.category || "Notícia") === "Notícia") ? "selected" : ""}>Notícia</option>
          <option value="Anúncio" ${(data.category === "Anúncio") ? "selected" : ""}>Anúncio</option>
          <option value="Evento" ${(data.category === "Evento") ? "selected" : ""}>Evento</option>
          <option value="Urgente" ${(data.category === "Urgente") ? "selected" : ""}>Urgente</option>
        </select>
      </div>

      <div class="input-wrapper">
        <label for="input-desc">Descrição</label>
        <textarea id="input-desc" required>${data.description}</textarea>
      </div>

      <div class="input-wrapper">
        <label for="input-video">Vídeo</label>
        <input
          id="input-video"
          type="url"
          placeholder="https://www.youtube.com/watch?v=U9pEWkb9_Gc"
          value="${data.video}"
        />
      </div>

      <div class="input-wrapper">
        <label for="input-photo">Foto</label>
        <input
          id="input-photo"
          type="url"
          placeholder="Link de imagem (imgur não funciona!)"
          required
          value="${data.img}"
        />
      </div>

      <div class="input-wrapper checkbox-row">
        <label for="input-featured">Destacar no topo</label>
        <input id="input-featured" type="checkbox" ${data.featured ? "checked" : ""} />
      </div>

      <button id="edit" data-index="${index}" style="pointer-events:auto; opacity: 1.0">Editar</button>
    `);
  });

  $(document).on("click", "#edit", function () {
    $("#create").hide();
    $("#main").show();

    const index = $(this).data("index");

    const inputs = ["title", "author", "category", "desc", "video", "photo"];
    const values = inputs.reduce((acc, input) => {
      acc[input] = $(`#input-${input}`).val();
      return acc;
    }, {});

    const { title, author, category, desc, video, photo } = values;
    const featured = $("#input-featured").is(":checked");

    $.post(
      `https://${RESOURCE}/editPost`,
      JSON.stringify({
        id: index + 1,
        title: title,
        author: author,
        category: category,
        featured: featured,
        description: desc,
        video: video,
        photo: photo,
      }),
      (data) => {
        if (data) {
          setTimeout(() => {
            reloadMainPage();
          }, 500);
        }
      }
    );
  });

  $(document).on("click", "#delete-news", function () {
    const index = $(this).data("index");

    $.post(
      `https://${RESOURCE}/deletePost`,
      JSON.stringify({
        id: index + 1,
      }),
      (data) => {
        if (data) {
          setTimeout(() => {
            reloadMainPage();
          }, 500);
        }
      }
    );
  });
});
