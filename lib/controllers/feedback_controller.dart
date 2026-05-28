import 'package:get/get.dart';
import '../model/ticket_model.dart';
import '../utils/network/api_service.dart';
import '../utils/toast_utils.dart';

class FeedbackController extends GetxController {
  var tickets = <TicketModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTickets();
  }

  Future<void> fetchTickets() async {
    try {
      isLoading.value = true;
      final result = await ApiService.getWorkOrderList();
      if (result['code'] == 200) {
        final List<dynamic> data = result['data'] ?? [];
        tickets.assignAll(data.map((json) => TicketModel.fromJson(json)).toList());
      } else {
        ToastUtils.error(result['msg'] ?? 'fetch_failed'.tr);
      }
    } catch (e) {
      ToastUtils.error('fetch_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshTickets() async {
    await fetchTickets();
  }
}
