package hiflying.blelink.demo;

import android.app.Application;

import hiflying.blelink.HFLog;
import com.orhanobut.logger.CsvFormatStrategy;
import com.orhanobut.logger.DiskLogAdapter;
import com.orhanobut.logger.Logger;

public class MyApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();

        Logger.clearLogAdapters();
        Logger.addLogAdapter(new DiskLogAdapter(CsvFormatStrategy.newBuilder().tag("BLE_LINK").build()));

        HFLog.clearLogAdapters();
        HFLog.addLogAdapter(new HFLog.HFLogAdapter() {

            @Override
            public void log(int level, String tag, String msg) {
                Logger.log(level, tag, msg, null);
            }
        });
    }
}
