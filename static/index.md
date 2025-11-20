# About

This is a simple NFC-reader and printer for Covfefe. It tracks statistics for coffees consumed and cleanings performed, writing a persistint log to a thermal printer.

# Installation

You can use the button below to install the pre-built firmware directly to your device via USB from the browser.

<div class="container">
    <div id="homeAssistantOptions">
        <div class="question-prompt">Select Option:</div>
        <div class="types">
            <label>
                <input type="radio" name="haOption" value="Printer" />
                <div class="name">Printer</div>
                <div class="description">Choose this option to install the printer firmware.</div>
            </label>
            <label>
                <input type="radio" name="haOption" value="Reader" />
                <div class="name">Reader</div>
                <div class="description">Choose this option to install the NFC-reader firmware.</div>
            </label>
        </div>
    </div>

    <esp-web-install-button class="hidden"></esp-web-install-button>
</div>

<script
    type="module"
    src="https://unpkg.com/esp-web-tools@9/dist/web/install-button.js?module"
></script>

<script>
    document.querySelectorAll('input[name="haOption"]').forEach(radio =>
        radio.addEventListener("change", function(event) {
            var selectedPlatform = event.target.value;
            var installButton = document.querySelector("esp-web-install-button");

            installButton.classList.add("hidden");

            document.querySelectorAll('input[name="haOption"]').forEach(optionRadio =>
                optionRadio.addEventListener("change", function() {
                    installButton.classList.remove("hidden");

                    if (this.value === "Reader") {
                        installButton.setAttribute("manifest", "firmware/covfefe-reader.manifest.json");
                    } else if (this.value === "Printer") {
                        installButton.setAttribute("manifest", "firmware/covfefe-printer.manifest.json");
                    }
                })
            );
        })
    );
</script>
