import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/theme/color_schemes.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CupertinoActivityIndicator(radius: 14),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 15,
                color: IosColors.secondaryLabel(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
