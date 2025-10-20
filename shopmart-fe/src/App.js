import React, { useState, useEffect, useRef } from 'react';
import { Trash2, Plus, AlertTriangle, CheckCircle } from 'lucide-react';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:5001/api';

export default function WarehouseApp() {
  const [inventory, setInventory] = useState([]);
  const [barcode, setBarcode] = useState('');
  const [loading, setLoading] = useState(false);
  const [currentProduct, setCurrentProduct] = useState(null);
  const [expiryDate, setExpiryDate] = useState('');
  const [quantity, setQuantity] = useState(1);
  const barcodeInputRef = useRef(null);

  useEffect(() => {
    fetchInventory();
  }, []);

  const fetchInventory = async () => {
    try {
      const res = await fetch(`${API_URL}/inventory`);
      const data = await res.json();
      setInventory(data.products || []);
    } catch (error) {
      console.error('Errore nel caricamento:', error);
    }
  };

  const handleBarcodeSearch = async () => {
    if (!barcode.trim()) return;

    setLoading(true);
    try {
      const res = await fetch(`${API_URL}/product/lookup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ barcode }),
      });
      const data = await res.json();

      if (data.success) {
        setCurrentProduct(data.product);
        setExpiryDate('');
        setQuantity(1);
      } else {
        alert('Prodotto non trovato');
        setCurrentProduct(null);
      }
    } catch (error) {
      console.error('Errore:', error);
      alert('Errore nella ricerca');
    } finally {
      setLoading(false);
      setBarcode('');
      barcodeInputRef.current?.focus();
    }
  };

  const handleAddProduct = async () => {
    if (!currentProduct || !expiryDate) {
      alert('Completa tutti i campi');
      return;
    }

    try {
      const res = await fetch(`${API_URL}/inventory/add`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          barcode: currentProduct.barcode,
          productName: currentProduct.productName,
          brand: currentProduct.brand,
          category: currentProduct.category,
          quantity,
          unit: currentProduct.unit,
          expiryDate,
          ingredients: currentProduct.ingredients,
          nutritionInfo: currentProduct.nutritionInfo,
          imageUrl: currentProduct.imageUrl,
          suggestions: [],
        }),
      });
      const data = await res.json();

      if (data.success) {
        await fetchInventory();
        setCurrentProduct(null);
        alert('Prodotto aggiunto al magazzino!');
      }
    } catch (error) {
      console.error('Errore:', error);
      alert('Errore nell\'aggiunta');
    }
  };

  const handleDeleteProduct = async (id) => {
    if (!window.confirm('Sei sicuro?')) return;

    try {
      const res = await fetch(`${API_URL}/inventory/${id}`, {
        method: 'DELETE',
      });
      const data = await res.json();

      if (data.success) {
        await fetchInventory();
      }
    } catch (error) {
      console.error('Errore:', error);
    }
  };

  const getStatusIcon = (status) => {
    if (status === 'SCADUTO' || status === 'URGENTE') {
      return <AlertTriangle className="w-5 h-5 text-red-500" />;
    }
    if (status === 'ATTENZIONE') {
      return <AlertTriangle className="w-5 h-5 text-orange-500" />;
    }
    return <CheckCircle className="w-5 h-5 text-green-500" />;
  };

  const getStatusColor = (status) => {
    if (status === 'SCADUTO') return 'bg-red-100 border-red-300';
    if (status === 'URGENTE') return 'bg-orange-100 border-orange-300';
    if (status === 'ATTENZIONE') return 'bg-yellow-100 border-yellow-300';
    return 'bg-green-100 border-green-300';
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter') {
      handleBarcodeSearch();
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 p-6">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-4xl font-bold text-slate-800 mb-2">📦 Magazzino Casa</h1>
        <p className="text-slate-600 mb-8">Gestisci i tuoi prodotti alimentari con scadenza</p>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Colonna sinistra: Ricerca e aggiunta */}
          <div className="lg:col-span-1">
            <div className="bg-white rounded-lg shadow-lg p-6 sticky top-6">
              <h2 className="text-xl font-bold text-slate-800 mb-6">Aggiungi Prodotto</h2>

              {/* Ricerca codice a barre */}
              <div className="mb-6">
                <label className="block text-sm font-medium text-slate-700 mb-2">
                  Codice a barre
                </label>
                <div className="flex gap-2">
                  <input
                    ref={barcodeInputRef}
                    type="text"
                    value={barcode}
                    onChange={(e) => setBarcode(e.target.value)}
                    onKeyPress={handleKeyPress}
                    placeholder="Scansiona qui..."
                    className="flex-1 px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  <button
                    onClick={handleBarcodeSearch}
                    disabled={loading}
                    className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:opacity-50"
                  >
                    {loading ? 'Cercando...' : 'Cerca'}
                  </button>
                </div>
              </div>

              {/* Dettagli prodotto trovato */}
              {currentProduct && (
                <div className="mb-6 p-4 bg-slate-50 rounded-lg border border-slate-200">
                  {/* Immagine prodotto */}
                  {currentProduct.imageUrl && (
                    <img
                      src={currentProduct.imageUrl}
                      alt={currentProduct.productName}
                      className="w-full h-48 object-contain rounded-lg mb-4 bg-white"
                    />
                  )}

                  <h3 className="font-bold text-slate-800 mb-1">{currentProduct.productName}</h3>
                  <p className="text-sm text-slate-600 mb-2">
                    <span className="font-semibold">Brand:</span> {currentProduct.brand}
                  </p>
                  <p className="text-xs text-slate-500 mb-4">
                    <span className="font-semibold">Categoria:</span> {currentProduct.category?.split(',')[0] || 'N/A'}
                  </p>

                  {/* Ingredienti */}
                  {currentProduct.ingredients && (
                    <details className="mb-4">
                      <summary className="text-xs font-semibold text-slate-700 cursor-pointer">
                        Ingredienti
                      </summary>
                      <p className="text-xs text-slate-600 mt-2">{currentProduct.ingredients}</p>
                    </details>
                  )}

                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1">
                        Quantità
                      </label>
                      <input
                        type="number"
                        min="1"
                        value={quantity}
                        onChange={(e) => setQuantity(parseInt(e.target.value))}
                        className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1">
                        Data scadenza
                      </label>
                      <input
                        type="date"
                        value={expiryDate}
                        onChange={(e) => setExpiryDate(e.target.value)}
                        className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>

                    <button
                      onClick={handleAddProduct}
                      className="w-full px-4 py-2 bg-green-500 text-white font-medium rounded-lg hover:bg-green-600 flex items-center justify-center gap-2"
                    >
                      <Plus className="w-4 h-4" /> Aggiungi al magazzino
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Colonna destra: Inventario */}
          <div className="lg:col-span-2">
            <div className="bg-white rounded-lg shadow-lg p-6">
              <h2 className="text-xl font-bold text-slate-800 mb-6">
                Inventario ({inventory.length} prodotti)
              </h2>

              {inventory.length === 0 ? (
                <div className="text-center py-12">
                  <p className="text-slate-500 text-lg">Nessun prodotto nel magazzino</p>
                  <p className="text-slate-400 text-sm">Inizia a scansionare codici a barre!</p>
                </div>
              ) : (
                <div className="space-y-3 max-h-[calc(100vh-200px)] overflow-y-auto">
                  {inventory.map((product) => (
                    <div
                      key={product.id}
                      className={`p-4 rounded-lg border-2 transition ${getStatusColor(product.status)}`}
                    >
                      <div className="flex items-start justify-between gap-4">
                        {/* Immagine prodotto */}
                        {product.imageUrl && (
                          <img
                            src={product.imageUrl}
                            alt={product.productName}
                            className="w-20 h-20 object-contain rounded-lg bg-white"
                          />
                        )}

                        <div className="flex gap-3 flex-1">
                          {getStatusIcon(product.status)}
                          <div className="flex-1">
                            <h3 className="font-bold text-slate-800">{product.productName}</h3>
                            <p className="text-xs text-slate-500">{product.brand}</p>
                            <p className="text-sm text-slate-600 mt-1">
                              Scadenza: {new Date(product.expiryDate).toLocaleDateString('it-IT')}
                            </p>
                            <p className="text-xs text-slate-500 mt-1">
                              {product.daysLeft === 0
                                ? 'Scade oggi'
                                : product.daysLeft > 0
                                  ? `Giorni rimanenti: ${product.daysLeft}`
                                  : `Scaduto da ${Math.abs(product.daysLeft)} giorni`}
                            </p>

                            {/* Ingredienti collassabili */}
                            {product.ingredients && (
                              <details className="mt-2">
                                <summary className="text-xs text-blue-600 cursor-pointer hover:underline">
                                  Vedi ingredienti
                                </summary>
                                <p className="text-xs text-slate-600 mt-1">{product.ingredients}</p>
                              </details>
                            )}
                          </div>
                        </div>

                        <div className="text-right flex items-center gap-3">
                          <div className="text-center">
                            <p className="text-2xl font-bold text-slate-800">{product.quantity}</p>
                            <p className="text-xs text-slate-500">{product.unit || 'pz'}</p>
                          </div>
                          <button
                            onClick={() => handleDeleteProduct(product.id)}
                            className="p-2 text-red-500 hover:bg-red-50 rounded-lg transition"
                          >
                            <Trash2 className="w-5 h-5" />
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}