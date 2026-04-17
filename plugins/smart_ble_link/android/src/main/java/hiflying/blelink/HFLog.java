package hiflying.blelink;

import android.util.Log;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.List;

public class HFLog {

    /**
     * Priority constant for the println method; use BleLog.v.
     */
    public static final int VERBOSE = Log.VERBOSE;

    /**
     * Priority constant for the println method; use BleLog.d.
     */
    public static final int DEBUG = Log.DEBUG;

    /**
     * Priority constant for the println method; use BleLog.i.
     */
    public static final int INFO = Log.INFO;

    /**
     * Priority constant for the println method; use BleLog.w.
     */
    public static final int WARN = Log.WARN;

    /**
     * Priority constant for the println method; use BleLog.e.
     */
    public static final int ERROR = Log.ERROR;

//    /**
//     * Priority constant for the println method.
//     */
//    public static final int ASSERT = Log.ASSERT;

    public static int level = VERBOSE;
    private static final List<HFLogAdapter> logAdapters = new ArrayList<>();

    public static interface HFLogAdapter {
        public void log(int level, String tag, String msg);
    }

    private HFLog() {
    }

    private abstract static class BleLogAction {

        private BleLogAction(int level, String tag, String msg, Object... args) {

            if (HFLog.isLoggable(level, tag)) {

                String text = createMessage(msg, args);
                log(tag, text);

                try {
                    logToAdapter(level, tag, text);
                } catch (Throwable e) {
                    e.printStackTrace();
                }
            }
        }

        private String createMessage(String msg, Object... args) {

            if (msg == null) {
                return "null";
            }

            return args == null || args.length == 0 ? msg : String.format(msg, args);
        }

        private void logToAdapter(int level, String tag, String msg) {

            for (HFLogAdapter adapter : logAdapters) {
                adapter.log(level, tag, msg);
            }
        }

        abstract void log(String tag, String msg);
    }

    /**
     * Send a {@link #VERBOSE} log message.
     *
     * @param tag  Used to identify the source of a log message.  It usually identifies
     *             the class or activity where the log call occurs.
     * @param msg  The message you would like logged.
     * @param args Arguments referenced by the format specifiers in the format
     *             string.  If there are more arguments than format specifiers, the
     *             extra arguments are ignored.  The number of arguments is
     *             variable and may be zero.  The maximum number of arguments is
     *             limited by the maximum dimension of a Java array as defined by
     *             <cite>The Java&trade; Virtual Machine Specification</cite>.
     */
    public static void v(String tag, String msg, Object... args) {

        new BleLogAction(VERBOSE, tag, msg, args) {

            @Override
            void log(String tag, String msg) {
                Log.v(tag, msg);
            }
        };
    }

    /**
     * Send a {@link #DEBUG} log message.
     *
     * @param tag  Used to identify the source of a log message.  It usually identifies
     *             the class or activity where the log call occurs.
     * @param msg  The message you would like logged.
     * @param args Arguments referenced by the format specifiers in the format
     *             string.  If there are more arguments than format specifiers, the
     *             extra arguments are ignored.  The number of arguments is
     *             variable and may be zero.  The maximum number of arguments is
     *             limited by the maximum dimension of a Java array as defined by
     *             <cite>The Java&trade; Virtual Machine Specification</cite>.
     */
    public static void d(String tag, String msg, Object... args) {

        new BleLogAction(DEBUG, tag, msg, args) {

            @Override
            void log(String tag, String msg) {
                Log.d(tag, msg);
            }
        };
    }

    /**
     * Send an {@link #INFO} log message.
     *
     * @param tag  Used to identify the source of a log message.  It usually identifies
     *             the class or activity where the log call occurs.
     * @param msg  The message you would like logged.
     * @param args Arguments referenced by the format specifiers in the format
     *             string.  If there are more arguments than format specifiers, the
     *             extra arguments are ignored.  The number of arguments is
     *             variable and may be zero.  The maximum number of arguments is
     *             limited by the maximum dimension of a Java array as defined by
     *             <cite>The Java&trade; Virtual Machine Specification</cite>.
     */
    public static void i(String tag, String msg, Object... args) {

        new BleLogAction(INFO, tag, msg, args) {

            @Override
            void log(String tag, String msg) {
                Log.i(tag, msg);
            }
        };
    }

    /**
     * Send a {@link #WARN} log message.
     *
     * @param tag  Used to identify the source of a log message.  It usually identifies
     *             the class or activity where the log call occurs.
     * @param msg  The message you would like logged.
     * @param args Arguments referenced by the format specifiers in the format
     *             string.  If there are more arguments than format specifiers, the
     *             extra arguments are ignored.  The number of arguments is
     *             variable and may be zero.  The maximum number of arguments is
     *             limited by the maximum dimension of a Java array as defined by
     *             <cite>The Java&trade; Virtual Machine Specification</cite>.
     */
    public static void w(String tag, String msg, Object... args) {

        new BleLogAction(WARN, tag, msg, args) {

            @Override
            void log(String tag, String msg) {
                Log.w(tag, msg);
            }
        };
    }

    /**
     * Send an {@link #ERROR} log message.
     *
     * @param tag  Used to identify the source of a log message.  It usually identifies
     *             the class or activity where the log call occurs.
     * @param msg  The message you would like logged.
     * @param args Arguments referenced by the format specifiers in the format
     *             string.  If there are more arguments than format specifiers, the
     *             extra arguments are ignored.  The number of arguments is
     *             variable and may be zero.  The maximum number of arguments is
     *             limited by the maximum dimension of a Java array as defined by
     *             <cite>The Java&trade; Virtual Machine Specification</cite>.
     */
    public static void e(String tag, String msg, Object... args) {

        new BleLogAction(ERROR, tag, msg, args) {

            @Override
            void log(String tag, String msg) {
                Log.e(tag, msg);
            }
        };
    }

    public static boolean isLoggable(int level, String tag) {

        if (HFLog.level > level) {
            return false;
        }

        if (tag != null && tag.length() > 23) {
            return false;
        }

        return true;
    }

    public static void addLogAdapter(@NonNull HFLogAdapter adapter) {
        logAdapters.add(adapter);
    }

    public static void clearLogAdapters() {
        logAdapters.clear();
    }
}
