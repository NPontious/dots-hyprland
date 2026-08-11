pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.common.functions
import qs.modules.common.utils
import qs.services
import qs.modules.common
import "../gCloud"

GCloudApi {
    id: root

    readonly property string tsvFilePath: `${Directories.screenshotTemp}/vision_output.tsv`

    function annotateImage(imageUri: string) {
        resetState();
        root.state = GCloudApi.State.Preparing;

        var seq = []; // command sequence

        const niceFilePath = StringUtils.shellSingleQuoteEscape(FileUtils.trimFileProtocol(imageUri))
        
        // Ensure tesseract exists
        seq = [ //
            ["bash", "-c", `if ! command -v tesseract >/dev/null; then exit 1; fi`], //
            (out) => { root.state = GCloudApi.State.Processing; },
            ["bash", "-c", `mkdir -p '${Directories.screenshotTemp}' && tesseract '${niceFilePath}' stdout tsv -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\n' '+' | sed 's/\\+$/\\n/') > '${tsvFilePath}' 2>/dev/null && python3 '${Quickshell.shellPath("scripts/images/tesseract-to-paragraphs.py")}' '${tsvFilePath}'`],
            (out) => {
                try {
                    root.outputData = JSON.parse(out);
                    root.finished();
                    root.state = GCloudApi.State.Done;
                } catch(e) {
                    root.state = GCloudApi.State.Error;
                    root.errorMessage = "Failed to parse local OCR response: " + e;
                    root.error(root.errorMessage);
                }
            }
        ]

        // Execute local OCR
        prepMultiproc.runSequence(seq);
    }

    MultiTurnProcess {
        id: prepMultiproc
        onExited: (code, status) => {
            if (code !== 0 && root.state === GCloudApi.State.Preparing) {
                root.state = GCloudApi.State.Error;
                root.errorMessage = "Tesseract is not installed or failed to start.";
                root.error(root.errorMessage);
            } else if (code !== 0 && root.state === GCloudApi.State.Processing) {
                root.state = GCloudApi.State.Error;
                root.errorMessage = "Tesseract or parsing script failed.";
                root.error(root.errorMessage);
            }
        }
    }
}
