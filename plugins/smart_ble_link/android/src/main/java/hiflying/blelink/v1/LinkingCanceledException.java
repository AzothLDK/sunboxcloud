package hiflying.blelink.v1;

import hiflying.blelink.LinkingError;
import hiflying.blelink.LinkingException;

class LinkingCanceledException extends LinkingException {

    public LinkingCanceledException() {
        super(LinkingError.CANCEL);
    }

    public LinkingCanceledException(String detailMessage) {
        super(LinkingError.CANCEL, detailMessage);
    }
}
