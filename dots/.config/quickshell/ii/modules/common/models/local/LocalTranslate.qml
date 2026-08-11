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

    readonly property string payloadFilePath: `${Directories.screenshotTemp}/translate_payload.json`

    function translateStrings(strings: list<string>) {
        root.state = GCloudApi.State.Preparing;
        var seq = [];

        const targetLang = Translation.languageCode;
        const payload = {
            "targetLanguageCode": targetLang,
            "contents": strings
        };

        seq.push([ //
            "bash", "-c", //
            `echo '${StringUtils.shellSingleQuoteEscape(JSON.stringify(payload))}' > '${payloadFilePath}' && python3 '${Quickshell.shellPath("scripts/images/translate-local.py")}' '${targetLang}' '${payloadFilePath}'`
        ]);

        seq.push(((out) => {
            root.handleApiOutput(out);
        }));

        multiproc.runSequence(seq);
    }

    MultiTurnProcess {
        id: multiproc
        onExited: (code, status) => {
            if (code !== 0) {
                root.state = GCloudApi.State.Error;
                root.errorMessage = "Translation script failed.";
                root.error(root.errorMessage);
            }
        }
    }
}
