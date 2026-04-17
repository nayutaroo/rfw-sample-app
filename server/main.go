package main

import (
	"encoding/json"
	"log/slog"
	"math/rand/v2"
	"net/http"
	"os"
	"path/filepath"
)

type product struct {
	ID     string `json:"id"`
	Name   string `json:"name"`
	Brand  string `json:"brand"`
	Price  string `json:"price"`
	Rating string `json:"rating"`
	Badge  string `json:"badge"`
}

// screenResponse はサーバーが返す「どのウィジェット定義＋どのデータ」の組み合わせ。
// 本番では user_id・時間帯・フィーチャーフラグ等でバリアントを選ぶ。
type screenResponse struct {
	Widget string            `json:"widget"`
	Data   map[string]string `json:"data"`
}

var products = []product{
	{ID: "p001", Name: "モイスチャライジングクリーム", Brand: "スキンケアブランドA", Price: "3,200", Rating: "★★★★☆", Badge: "ベストセラー"},
	{ID: "p002", Name: "ビタミンCセラム", Brand: "スキンケアブランドB", Price: "5,800", Rating: "★★★★★", Badge: "新商品"},
	{ID: "p003", Name: "サンスクリーンSPF50", Brand: "スキンケアブランドC", Price: "2,500", Rating: "★★★☆☆", Badge: "セール中"},
}

// screenVariants は画面ごとのバリアント定義。
// widget × data の組み合わせを列挙しておき、selectVariant が1つを選ぶ。
var screenVariants = map[string][]screenResponse{
	"product": {
		{
			Widget: "product_card",
			Data:   productToMap(products[0]),
		},
		{
			Widget: "product_card",
			Data:   productToMap(products[2]),
		},
		{
			Widget: "product_card_featured",
			Data:   productToMap(products[1]),
		},
	},
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /widgets/{name}", handleWidget)
	mux.HandleFunc("GET /data/products", handleProducts)
	mux.HandleFunc("GET /screen/{name}", handleScreen)

	slog.Info("server starting", "addr", ":8080")
	if err := http.ListenAndServe(":8080", withCORS(mux)); err != nil {
		slog.Error("server failed", "err", err)
	}
}

func handleWidget(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("name")
	path := filepath.Join("static", name+".rfw")

	data, err := os.ReadFile(path)
	if err != nil {
		slog.Warn("widget not found", "name", name)
		http.NotFound(w, r)
		return
	}

	w.Header().Set("Content-Type", "application/octet-stream")
	if _, err := w.Write(data); err != nil {
		slog.Error("write failed", "err", err)
	}
}

func handleProducts(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(products); err != nil {
		slog.Error("encode failed", "err", err)
	}
}

// handleScreen はリクエストのコンテキストに応じてバリアントを選んで返す。
// 現在はランダム選択。本番では r のヘッダー・クエリ等を使って選択ロジックを差し込む。
func handleScreen(w http.ResponseWriter, r *http.Request) {
	name := r.PathValue("name")

	variants, ok := screenVariants[name]
	if !ok {
		http.NotFound(w, r)
		return
	}

	variant := selectVariant(variants, r)
	slog.Info("screen served", "name", name, "widget", variant.Widget)

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(variant); err != nil {
		slog.Error("encode failed", "err", err)
	}
}

// selectVariant がバリアント選択ロジックの差し込み口。
// 現在はランダム。本番では r から user_id・時間帯・フラグを読んで決定する。
func selectVariant(variants []screenResponse, _ *http.Request) screenResponse {
	return variants[rand.IntN(len(variants))]
}

func withCORS(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		h.ServeHTTP(w, r)
	})
}

func productToMap(p product) map[string]string {
	return map[string]string{
		"id":     p.ID,
		"name":   p.Name,
		"brand":  p.Brand,
		"price":  p.Price,
		"rating": p.Rating,
		"badge":  p.Badge,
	}
}
