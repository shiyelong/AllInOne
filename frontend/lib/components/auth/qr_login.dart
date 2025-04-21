import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../localization/app_localizations.dart';
import 'third_party_login.dart';

/// 二维码登录组件
class QrLoginView extends StatelessWidget {
  final bool isLoading;
  final String qrCodeData;
  final bool isQrScanned;
  final String? errorMsg;
  final Function() onGenerateQrCode;
  final Function() onToggleQrCode;
  final Function(String) onThirdPartyLogin;
  final List<Map<String, dynamic>> thirdPartyPlatforms;

  const QrLoginView({
    Key? key,
    required this.isLoading,
    required this.qrCodeData,
    required this.isQrScanned,
    required this.errorMsg,
    required this.onGenerateQrCode,
    required this.onToggleQrCode,
    required this.onThirdPartyLogin,
    required this.thirdPartyPlatforms,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'scan_qr_login'.tr(context),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'use_mobile_scan'.tr(context),
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                if (isLoading)
                  const CircularProgressIndicator()
                else if (qrCodeData.isNotEmpty)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qrCodeData,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isQrScanned)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.phone_android, color: Colors.green, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'scan_success'.tr(context),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'confirm_on_mobile'.tr(context),
                                style: const TextStyle(color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: onGenerateQrCode,
                            icon: const Icon(Icons.refresh),
                            label: Text('refresh_qr_code'.tr(context)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: onToggleQrCode,
                            icon: const Icon(Icons.keyboard),
                            label: Text('password_login'.tr(context)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: onGenerateQrCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('generate_qr_code'.tr(context)),
                  ),
                if (errorMsg != null && errorMsg!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      errorMsg!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'any_problems'.tr(context),
            style: const TextStyle(color: Colors.white70),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('customer_service_email'.tr(context)),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: Text('contact_customer_service'.tr(context), style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onToggleQrCode,
            icon: const Icon(Icons.arrow_back),
            label: Text('back_to_login_register'.tr(context)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white30),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 40),
          // 添加第三方登录到二维码页面
          ThirdPartyLogin(
            platforms: thirdPartyPlatforms,
            onLoginPressed: onThirdPartyLogin,
          )
        ],
      ),
    );
  }
}
