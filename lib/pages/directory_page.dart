import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/directory_controller.dart';
import '../utils/constants.dart';
import '../widgets/health_unit_card.dart';
import '../widgets/hospital_card.dart';

class DirectoryPage extends StatefulWidget {
  const DirectoryPage({super.key});

  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  final _controller = DirectoryController();
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode(); 
  bool _hasAutoSearched = false;

  @override
  void initState() {
    super.initState();
    _controller.loadLocalUnits();
    
    
    _searchCtrl.addListener(() {
      _controller.loadPlaceSuggestions(_searchCtrl.text);
    });
    
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _controller.clearSuggestions();
      }
    });
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAutoSearched && !_controller.isLoading) {
      _hasAutoSearched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.searchByCity('Manila');
      });
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: [
            
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _focusNode,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (v) {
                            _controller.searchByCity(v.trim());
                            _focusNode.unfocus();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search city or area…',
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.my_location, color: AppConstants.redPrimary),
                              tooltip: 'Near me',
                              onPressed: _controller.searchNearMe,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          _controller.searchByCity(_searchCtrl.text.trim());
                          _focusNode.unfocus();
                        },
                        child: const Text('Go'),
                      ),
                    ],
                  ),
                 
                  if (_controller.placeSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _controller.placeSuggestions
                            .map((place) => ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.location_city, size: 20, color: Colors.grey),
                                  title: Text(place, style: const TextStyle(fontSize: 14)),
                                  onTap: () {
                                    _searchCtrl.text = place;
                                    _controller.searchByCity(place);
                                    _focusNode.unfocus();
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _controller.locationLabel,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
            
            Expanded(
              child: RefreshIndicator(
                color: AppConstants.redPrimary,
                onRefresh: () => _controller.searchByCity(
                  _searchCtrl.text.trim().isEmpty ? 'Manila' : _searchCtrl.text.trim(),
                ),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    if (_controller.localUnits.isNotEmpty) ...[
                      const _SectionHeader('Barangay Health Centers'),
                      ..._controller.localUnits.map(
                        (u) => HealthUnitCard(unit: u, onCall: () => _call(u.phone)),
                      ),
                    ],
                    const _SectionHeader('Nearby Hospitals & Clinics (Nearest First)'),
                    if (_controller.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_controller.error != null)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Text(_controller.error!, textAlign: TextAlign.center),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => _controller.searchByCity('Manila'),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_controller.hospitals.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text('Search a city or tap the location icon to find nearby facilities.'),
                        ),
                      )
                    else
                      ..._controller.hospitals.map(
                        (h) => HospitalCard(
                          hospital: h,
                          onCall: h.phone == null ? null : () => _call(h.phone!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}