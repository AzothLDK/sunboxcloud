package hiflying.blelink;

public class LinkingException extends Exception {

    private LinkingError error;
    private Object data;

    public LinkingError getError() {
        return error;
    }

    public Object getData() {
        return data;
    }

    public void setData(Object data) {
        this.data = data;
    }

    public LinkingException(LinkingError error) {
        this(error, null, null);
    }

    public LinkingException(LinkingError error, String message) {
        this(error, message, null);
    }

    public LinkingException(LinkingError error, String message, Object data) {
        super(message);
        this.error = error;
        this.data = data;
    }

    @Override
    public String toString() {
        return "LinkingException{" +
                "error=" + error +
                ", message=" + getMessage() +
                ", data=" + data +
                "} ";
    }
}
