async function fetchNui(eventName, data = {}, resourceName = "phone-bank") {
    const options = {
        method: 'post',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data),
    };

    const resource = window.GetParentResourceName ? GetParentResourceName() : resourceName;

    const resp = await fetch(`https://${resource}/${eventName}`, options);

    return await resp.json();
}

var results = {
  pix: { key: "", value: 0 },
  trans: { passport: 0, value: 0 },
  user: { fines: {}, pix: null },
};

$(document).ready(() => {
  const formatCurrency = (value) => {
    const formated = value.toLocaleString("pt-BR", {
      style: "currency",
      currency: "BRL",
    });

    return formated;
  };

  const createInvoice = (list) => {
    if (list) {
      $("#invoice-list").html("");

      list.sort((a, b) => b.created_at - a.created_at);

      list.map((item) => {
        const date = new Date(item.created_at * 1000);

        const html = `
        <li>
          <div class="invoice-description">
            <strong id="invoice-title">${item.title}</strong>
            <span id="invoice-text">${item.content}</span>
          </div>
          <div id="invoice-value">
            <strong style="color: ${
              item.type === "spent" ? "rgb(255, 103, 103)" : "rgb(187, 253, 87)"
            }">${formatCurrency(item.value)}</strong>
            <span>${date.toLocaleString("pt-BR")}</span>
          </div>
        </li>
      `;

        $("#invoice-list").append(html);
      });
    }
  };

  const reset = () => {
    $(".input").prop("value", "");
    $("#transfer-send, #pix-send").css({
      opacity: 0.5,
      "pointer-events": "none",
    });
  };

  const update = () => {
    fetchNui("getUser", null, "phone-bank").then((data) => {
      if (data) {
        $("#balance").text(formatCurrency(data.money));
        createInvoice(data.invoice);
        results.user.fines = data.fines;
        results.user.pix = data.pix;
      }
    });
  };

  setTimeout(() => {
    fetchNui("getUser", null, "phone-bank").then((data) => {
        // Validação direta: Se não houver data ou identity, encerra para evitar o erro
        if (!data || !data.identity) return;

        results.user.fines = data.fines;
        results.user.pix = data.pix;
      
        $("#load-main").fadeOut();

        $(".main").html(`
            <div class="top-infos">
                <span id="user">Olá, <b>${data.identity.Name} ${data.identity.Lastname}!</b></span>
                <button id="refresh"><i class="fa-solid fa-arrows-rotate"></i></button>
            </div>
            <div class="card">
                <span id="card-owner">${data.identity.Name} <b>${data.identity.Lastname}</b></span>
                <span id="card-number">0567 4664 8327 0442</span>
                <img class="bank-master" src="assets/master.png" />
            </div>
            <div id="total-value">
                <span>Saldo total</span>
                <strong id="balance">${formatCurrency(data.money)}</strong>
            </div>
            <ul id="bank-buttons">
                <li id="pix">
                    <button><i class="fa-brands fa-pix"></i></button>
                    <span>Pix</span>
                </li>
                <li id="transfer">
                    <button><i class="fa-solid fa-money-bill-transfer"></i></button>
                    <span>Transferir</span>
                </li>
                <li id="fines">
                    <button><i class="fa-solid fa-file-invoice"></i></button>
                    <span>Multas</span>
                </li>
            </ul>
            <div class="invoice">
                <strong>Extrato Bancário</strong>
                <ul id="invoice-list"></ul>
            </div>
        `);

        if (data.invoice) {
            createInvoice(data.invoice);
        }
    });
}, 1500);

  // Clicks

  const showSection = (sectionClass) => {
    reset();
    update();

    $(".pix-buttons").html(`
      ${
        !results.user.pix
          ? `<button id="pix-button" data-value="create">Criar Pix</button>`
          : `
            <button id="pix-button" data-value="my">Meu Pix</button>
            <button id="pix-button" data-value="edit">Editar Pix</button>
            <button id="pix-button" data-value="delete">Deletar Pix</button>
          `
      }
      
      <button id="pix-button" data-value="trans">Transferir</button>
    `);
    $(".pix-buttons").show();

    $(".transfer-box").show();

    $(
      ".main, .pix, .transfer, .fines, .fines-detail, .request, .pix-box"
    ).hide();
    $(sectionClass).show();
  };

  $(document).on("click", "#pix", () => showSection(".pix"));

  $(document).on("click", "#pix-button", function () {
    const data = $(this).data("value");

    $(".pix-buttons").hide();
    $(".pix-box").show();

    let html;
    if (data === "trans") {
      html = `
        <span>Envie o seu dinheiro!</span>
        <form>
          <label for="input-pix">Chave Pix</label>
          <input type="text" id="input-pix" class="input" value="" />
          <label for="input-pix-value" style="margin-top: 0.5rem"
            >Valor</label
          >
          <input
            type="number"
            id="input-pix-value"
            class="input"
            value=""
          />
        </form>
        <button id="pix-send">Enviar</button>
      `;
    } else if (data === "create") {
      html = `
        <span>Crie a sua chave pix!</span>
        <form>
          <label for="input-pix">Chave Pix</label>
          <input type="text" id="input-pix" class="input" value="" />
        </form>
        <button id="pix-create" data-method="create">Criar</button>
      `;
    } else if (data === "my") {
      showSection(".main");
      sendNotification({
        title: "Pix",
        content: "Meu PIX: " + results.user.pix,
      });
      return;
    } else if (data === "edit") {
      html = `
        <span>Edite a sua chave pix!</span>
        <form>
          <label for="input-pix">Chave Pix</label>
          <input type="text" id="input-pix" class="input" value="" />
        </form>
        <button id="pix-create" data-method="edit">Editar</button>
      `;
    } else if (data === "delete") {
      fetchNui(
        "Pix",
        { method: "delete" },
        "phone-bank"
      ).then((data) => {
        if (data) {
          if (data.error) {
            showSection(".main");
            sendNotification({
              title: "Sistema",
              content: data.error,
            });
            return;
          }

          showSection(".main");
        }
      });
      return;
    }

    $(".pix-box").html(html);
  });

  $(document).on("click", "#pix-create", function () {
    const method = $(this).data("method");

    $(".pix-box").hide();

    $("#load-text").text("Criando...");
    $("#load-pix").fadeIn();
    setTimeout(() => {
      $("#load-pix").fadeOut();

      fetchNui(
        "Pix",
        { method: method, key: results.pix.key },
        "phone-bank"
      ).then((data) => {
        if (data) {
          if (data.error) {
            showSection(".pix");
            sendNotification({
              title: "Sistema",
              content: data.error,
            });
            return;
          }

          showSection(".main");
        }
      });
    }, 1000);
  });

  $(document).on("click", "#transfer", () => showSection(".transfer"));

  $(document).on("click", "#fines", function () {
    showSection(".fines");

    $("#fines-list").html("");
    $("#fines-list").show();

    results.user.fines.map((item, index) => {
      const html = `
        <li>
          <div class="fines-info">
            <span id="fines-description">${item.reason}</span>
            <strong id="fines-value">${formatCurrency(item.value)}</strong>
          </div>
          <div id="fines-button">
            <button id="fines-pay" data-index="${item.id}">Pagar</button>
            <button id="fines-details" data-index="${index}">
              <i class="fa-solid fa-info"></i>
            </button>
          </div>
        </li>
      `;

      $("#fines-list").append(html);
    });
  });

  $(document).on("click", "#fines-details", function () {
    const index = parseInt($(this).data("index"));
    const date = new Date(results.user.fines[index].created_at * 1000);

    showSection(".fines-detail");

    $(".fines-box").html(`
      <li>
        <span>Motivo</span>
        <strong>${results.user.fines[index].reason}</strong>
      </li>
      <li>
        <span>Valor</span>
        <strong>${formatCurrency(results.user.fines[index].value)}</strong>
      </li>
      <li>
        <span>Data</span>
        <strong>${date.toLocaleDateString("pt-BR")}</strong>
      </li>
      <li>
        <span>Descrição</span>
        <strong>${results.user.fines[index].content}</strong>
      </li>
    `);
  });

  $(document).on("click", "#close", function () {
    const data = $(this).data("previous");

    showSection(data || ".main");
  });

  $(document).on("click", "#pix-send", function () {
    $(".pix-box").hide();

    $("#load-text").text("Carregando...");
    $("#load-pix").fadeIn();
    setTimeout(() => {
      $("#load-pix").fadeOut();

      fetchNui(
        "getReceiver",
        { method: "pix", pix: results.pix.key },
        "phone-bank"
      ).then((data) => {
        if (data) {
          if (data.error) {
            showSection(".pix");
            sendNotification({
              title: "Sistema",
              content: data.error,
            });
            return;
          }

          results.pix.key = data.passport;

          $("#request-pix").html(`
              <strong>${formatCurrency(results.pix.value)}</strong>
              <span>para <b>${data.Name + " " + data.Lastname}</b></span>
              <p>Tem certeza de que deseja prosseguir com esta transação?</p>
              <button id="request-confirm" data-value="pix">Confirmar</button>
            `);

          $("#request-pix").show();
        } else {
          showSection(".pix");
          sendNotification({
            title: "Sistema",
            content:
              "Ocorreu uma falha em nosso sistema. Por favor, tente novamente mais tarde!",
          });
        }
      });
    }, 1000);
  });

  $(document).on("click", "#transfer-send", function () {
    $(".transfer-box").hide();

    $("#load-text").text("Carregando...");
    $("#load-trans").fadeIn();
    setTimeout(() => {
      $("#load-trans").fadeOut();

      fetchNui(
        "getReceiver",
        { method: "transfer", nuser_id: results.trans.passport },
        "phone-bank"
      ).then((data) => {
        if (data) {
          if (data.error) {
            showSection(".transfer");
            sendNotification({
              title: "Sistema",
              content: data.error,
            });
            return;
          }

          $("#request-trans").html(`
              <strong>${formatCurrency(results.trans.value)}</strong>
              <span>para <b>${data.Name + " " + data.Lastname}</b></span>
              <p>Tem certeza de que deseja prosseguir com esta transação?</p>
              <button id="request-confirm" data-value="trans">Confirmar</button>
            `);

          $("#request-trans").show();
        } else {
          showSection(".transfer");
          sendNotification({
            title: "Sistema",
            content:
              "Ocorreu uma falha em nosso sistema. Por favor, tente novamente mais tarde!",
          });
        }
      });
    }, 1000);
  });

  $(document).on("click", "#request-confirm", function () {
    const method = $(this).data("value");

    $(`#request-${method}`).hide();
    $("#load-text").text("Transferindo...");
    $(`#load-${method}`).fadeIn();
    setTimeout(() => {
      $(`#load-${method}`).fadeOut();

      fetchNui(
        "sendMoney",
        {
          method: method === "pix" ? "Pix" : "Transferência",
          nuser_id: results[method][method === "pix" ? "key" : "passport"],
          value: results[method].value,
        },
        "phone-bank"
      ).then((data) => {
        if (data) {
          if (data.error) {
            showSection(".main");
            sendNotification({
              title: "Sistema",
              content: data.error,
            });
            return;
          }

          showSection(".main");
        }
      });
    }, 1000);
  });

  $(document).on("click", "#fines-pay", function () {
    const index = parseInt($(this).data("index"));

    $("#fines-list").hide();

    $("#load-text").text("Pagando...");
    $(`#load-fine`).fadeIn();
    setTimeout(() => {
      $(`#load-fine`).fadeOut();

      fetchNui(
        "payFine",
        {
          fine_id: index,
        },
        "phone-bank"
      ).then((data) => {
        if (data) {
          if (data.error) {
            showSection(".main");
            sendNotification({
              title: "Sistema",
              content: data.error,
            });
            return;
          }

          showSection(".main");
        }
      });
    }, 1000);
  });

  $(document).on("click", "#refresh", function() {
    $(".main").html(`
      <div id="load-main" class="loading" style="margin-top: 25rem">
        <i class="fa-solid fa-spinner"></i>
      </div>
    `);

    setTimeout(() => {
      fetchNui("getUser", null, "phone-bank").then((data) => {
        if (data) {
          results.user.fines = data.fines;
          results.user.pix = data.pix;
        
          $("#load-main").fadeOut();

          $(".main").html(`
            <div class="top-infos">
              <span id="user">Olá, <b>${data.identity.Lastname}!</b></span>
              <button id="refresh"><i class="fa-solid fa-arrows-rotate"></i></button>
            </div>
            <div class="card">
              <span id="card-owner">${data.identity.Name} <b>${
            data.identity.Lastname
          }</b></span>
              <span id="card-number">0567 4664 8327 0442</span>
              <img class="bank-master" src="assets/master.png" />
            </div>
            <div id="total-value">
              <span>Saldo total</span>
              <strong id="balance">${formatCurrency(data.money)}</strong>
            </div>
            <ul id="bank-buttons">
              <li id="pix">
                <button><i class="fa-brands fa-pix"></i></button>
                <span>Pix</span>
              </li>
              <li id="transfer">
                <button><i class="fa-solid fa-money-bill-transfer"></i></button>
                <span>Transferir</span>
              </li>
              <li id="fines">
                <button><i class="fa-solid fa-file-invoice"></i></button>
                <span>Multas</span>
              </li>
            </ul>
            <div class="invoice">
              <strong>Extrato Bancário</strong>
              <ul id="invoice-list"></ul>
            </div>
          `);

          createInvoice(data.invoice);
        }
      });
    }, 1500);
  });

  // Inputs

  const input_pix = (method, result) => {
    let allow;

    if (method === "text") {
      allow =
        !isNaN(results.pix.value) && results.pix.value > 0 && result !== "";
      results.pix.key = result;
    } else {
      allow = !isNaN(result) && result > 0 && results.pix.key !== "";
      results.pix.value = result;
    }

    $("#pix-send").css({
      opacity: allow ? 1 : 0.5,
      "pointer-events": allow ? "auto" : "none",
    });

    $("#pix-create").css({
      opacity: results.pix.key !== "" ? 1 : 0.5,
      "pointer-events": results.pix.key !== "" ? "auto" : "none",
    });
  };

  const input_transfer = (method, result) => {
    let allow;

    if (method === "text") {
      allow =
        !isNaN(results.trans.value) && results.trans.value > 0 && result > 0;
      results.trans.passport = result;
    } else {
      allow = !isNaN(result) && result > 0 && results.trans.passport > 0;
      results.trans.value = result;
    }

    $("#transfer-send").css({
      opacity: allow ? 1 : 0.5,
      "pointer-events": allow ? "auto" : "none",
    });
  };

  $(document).on("input", "#input-pix", function () {
    const value = $(this).val();
    input_pix("text", value);
  });

  $(document).on("input", "#input-pix-value", function () {
    const value = parseInt($(this).val());
    input_pix("", value);
  });

  $(document).on("input", "#input-trans", function () {
    const value = parseInt($(this).val());
    input_transfer("text", value);
  });

  $(document).on("input", "#input-trans-value", function () {
    const value = parseInt($(this).val());
    input_transfer("", value);
  });
});
