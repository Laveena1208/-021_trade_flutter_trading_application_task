/// The 10 stocks supported across the entire app.
/// Prices are stored in PAISE (int) everywhere in the app to avoid
/// floating point drift. 1 Rupee = 100 Paise.
class StockDef {
  final String symbol;
  final String name;
  final int basePricePaise;

  const StockDef({
    required this.symbol,
    required this.name,
    required this.basePricePaise,
  });
}

const List<StockDef> kStocks = [
  StockDef(symbol: 'RELIANCE', name: 'Reliance Industries', basePricePaise: 295000),
  StockDef(symbol: 'TCS', name: 'Tata Consultancy Services', basePricePaise: 385000),
  StockDef(symbol: 'INFY', name: 'Infosys', basePricePaise: 185000),
  StockDef(symbol: 'HDFCBANK', name: 'HDFC Bank', basePricePaise: 165000),
  StockDef(symbol: 'ICICIBANK', name: 'ICICI Bank', basePricePaise: 125000),
  StockDef(symbol: 'SBIN', name: 'State Bank of India', basePricePaise: 82000),
  StockDef(symbol: 'ITC', name: 'ITC Limited', basePricePaise: 46500),
  StockDef(symbol: 'LT', name: 'Larsen & Toubro', basePricePaise: 360000),
  StockDef(symbol: 'BHARTIARTL', name: 'Bharti Airtel', basePricePaise: 158000),
  StockDef(symbol: 'AXISBANK', name: 'Axis Bank', basePricePaise: 115000),
];

StockDef stockBySymbol(String symbol) =>
    kStocks.firstWhere((s) => s.symbol == symbol);

/// Starting wallet balance: ₹10,00,000
const int kStartingWalletBalancePaise = 100000000;
