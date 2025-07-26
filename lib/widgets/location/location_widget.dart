import 'package:flutter/material.dart';
import 'package:location/location.dart';
import '../../services/location_service.dart';

class LocationWidget extends StatefulWidget {
  final Function(LocationData)? onLocationReceived;
  final bool showRefreshButton;

  const LocationWidget({
    Key? key,
    this.onLocationReceived,
    this.showRefreshButton = true,
  }) : super(key: key);

  @override
  State<LocationWidget> createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget> {
  final LocationService _locationService = LocationService();
  LocationData? _currentPosition;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      LocationData? position = await _locationService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });

        if (widget.onLocationReceived != null) {
          widget.onLocationReceived!(position);
        }
      } else {
        setState(() {
          _error = 'Failed to get location';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Current Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (widget.showRefreshButton && !_isLoading)
                  IconButton(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Column(
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    child: const Text('Retry'),
                  ),
                ],
              )
            else if (_currentPosition != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationRow('Latitude',
                      _currentPosition!.latitude?.toStringAsFixed(6) ?? 'Unknown'),
                  const SizedBox(height: 8),
                  _buildLocationRow('Longitude',
                      _currentPosition!.longitude?.toStringAsFixed(6) ?? 'Unknown'),
                  const SizedBox(height: 8),
                  _buildLocationRow(
                      'Accuracy',
                      _currentPosition!.accuracy != null
                          ? '±${_currentPosition!.accuracy!.toStringAsFixed(1)}m'
                          : 'Unknown'),
                  const SizedBox(height: 8),
                  _buildLocationRow('Timestamp',
                      _formatTimestamp(DateTime.fromMillisecondsSinceEpoch(
                          _currentPosition!.time?.toInt() ?? 0))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null || timestamp.millisecondsSinceEpoch == 0) return 'Unknown';

    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }
}
