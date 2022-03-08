import 'package:dio/dio.dart';
import 'package:popwork/popwork.dart';
import 'package:popwork/src/endpoint/endpoint.dart';
import 'package:popwork/src/http/provider/dio/helpers/request_helper.dart';
import 'package:popwork/src/http/provider/network_provider.dart';
import 'package:popwork/src/popwork.dart';
import 'package:popwork/src/response/network_response.dart';

class DioProvider implements NetworkProvider {
  Future<NetworkResponse> _safeRequest({
    required RequestHelper requestHelper,
    required Endpoint endpoint,
  }) async {
    Dio _provider = Popwork.dioCreator
      ..options.connectTimeout =
          endpoint.timeout ?? HttpConfig.timeoutConfig.connectionTimeout;

    try {
      return await requestHelper.makeRequestHelper(
        endpoint: endpoint,
        httpProvider: _provider,
      );
    } on DioError catch (e) {
      var response = e.response;
      if (response != null && response.statusCode != null) {
        return NetworkResponse(
          data: response.data,
          status: response.statusCode!,
          typeError: e.type,
        );
      } else {
        return NetworkResponse(
          message: e.message,
          typeError: e.type,
          status: 520,
          data: null,
        );
      }
    }
  }

  @override
  Future<NetworkResponse> get({required Endpoint endpoint}) async {
    final GetHelper requestHelper = GetHelper();
    return _safeRequest(requestHelper: requestHelper, endpoint: endpoint);
  }

  @override
  Future<NetworkResponse> post({required Endpoint endpoint}) async {
    return _safeRequest(requestHelper: PostHelper(), endpoint: endpoint);
  }

  @override
  Future<NetworkResponse> put({required Endpoint endpoint}) {
    final PutHelper requestHelper = PutHelper();
    return _safeRequest(requestHelper: requestHelper, endpoint: endpoint);
  }

  @override
  Future<NetworkResponse> delete({required Endpoint endpoint}) {
    final DeleteHelper requestHelper = DeleteHelper();
    return _safeRequest(requestHelper: requestHelper, endpoint: endpoint);
  }

  @override
  Future<NetworkResponse> patch({required Endpoint endpoint}) {
    return _safeRequest(requestHelper: PatchHelper(), endpoint: endpoint);
  }
}
