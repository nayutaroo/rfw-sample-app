package main

import (
	"encoding/json"
	"log/slog"
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

var products = []product{
	{ID: "p001", Name: "モイスチャライジングクリーム", Brand: "スキンケアブランドA", Price: "3,200", Rating: "★★★★☆", Badge: "ベストセラー"},
	{ID: "p002", Name: "ビタミンCセラム", Brand: "スキンケアブランドB", Price: "5,800", Rating: "★★★★★", Badge: "新商品"},
	{ID: "p003", Name: "サンスクリーンSPF50", Brand: "スキンケアブランドC", Price: "2,500", Rating: "★★★☆☆", Badge: "セール中"},
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /widgets/{name}", handleWidget)
	mux.HandleFunc("GET /data/products", handleProducts)

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
