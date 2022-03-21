import 'dart:async';

import 'package:pop_network/src/endpoint/endpoint.dart';
import 'package:pop_network/src/http/provider/dio/dio_provider.dart';
import 'package:pop_network/src/http/provider/network_provider.dart';
import 'package:pop_network/src/methods/http_method.dart';
import 'package:pop_network/src/mock/mock_provider.dart';
import 'package:pop_network/src/network.dart';
import 'package:pop_network/src/raw_response_notifier/raw_response_notifiable.dart';
import 'package:pop_network/src/raw_response_notifier/raw_response_notifier.dart';
import 'package:pop_network/src/response/api_result.dart';
import 'package:pop_network/src/response/network_response.dart';
import 'package:pop_network/src/response/states/apiError/api_error.dart';
import 'package:pop_network/src/response/states/internal_error.dart';
import 'package:pop_network/src/response/states/success.dart';

///
///Responsible for initiating the request for your api
///To use it, it is only necessary to call the `.request` function or pass the
///endpoint as a parameter. To learn more about the endpoint settings [click here](https://github.com/PopcodeMobile/popnetwork/blob/main/doc/endpoint.md)
class ApiManager {
  static final NetworkProvider _networkProvider = DioProvider();
  static final RawResponseNotifier _rawResponseNotifier = RawResponseNotifier();

  static void addNotifiable(RawResponseNotifiable listener) {
    _rawResponseNotifier.addListener(listener);
  }

  static void removeNotifiable(RawResponseNotifiable listener) {
    _rawResponseNotifier.removeListener(listener);
  }

  static InternalError _makeInternalError() {
    return InternalError(
      message: Network.mapApiError.messageDefault,
      statusCode: 520,
    );
  }

  static Future<ApiResult> _request({Endpoint? endpoint}) async {
    final _endpoint = endpoint ?? Endpoint();
    try {
      final NetworkResponse response = await _endpoint.method.request(
        http: _networkProvider,
        endpoint: _endpoint,
      );
      var statusCode = response.status;

      if (statusCode != null && statusCode >= 200 && statusCode < 400) {
        return Future<Success>.value(
          Success(data: response.data, statusCode: statusCode),
        );
      }

      _rawResponseNotifier.notify(response);
      final mappedErrors = Network.mapApiError.mappingError(response.data);

      return Future<ApiError>.value(ApiError(
        error: mappedErrors,
        statusCode: statusCode ?? 520,
        path: response.data['path'],
        timestamp: response.data['timestamp'],
      ));
    } catch (_) {
      return _makeInternalError();
    }
  }

  static Future<ApiResult> requestApi({Endpoint? endpoint}) {
    if (Network.isMock) {
      return requestMock(endpoint: endpoint);
    }
    return _request(endpoint: endpoint);
  }

  static Future<ApiResult> requestMock({Endpoint? endpoint}) {
    final mock = MockProvider();
    return mock.request(endpoint: endpoint);
  }
}
