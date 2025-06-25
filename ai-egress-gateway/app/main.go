package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/bedrockruntime"
)

var (
	client              *bedrockruntime.Client
	inferenceProfileARN string
)

func main() {
	accountID := os.Getenv("AWS_ACCOUNT_ID")
	region := os.Getenv("AWS_REGION")
	modelID := os.Getenv("BEDROCK_MODEL_ID")
	if accountID == "" || region == "" || modelID == "" {
		log.Fatal("Missing environment variables: AWS_ACCOUNT_ID, AWS_REGION, and BEDROCK_MODEL_ID must be set")
	}
	inferenceProfileARN = fmt.Sprintf("arn:aws:bedrock:%s:%s:inference-profile/%s", region, accountID, modelID)

	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	if err != nil {
		log.Fatalf("unable to load SDK config, %v", err)
	}
	client = bedrockruntime.NewFromConfig(cfg)

	http.HandleFunc("/ask", handleAsk)
	log.Println("Server listening on http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func handleAsk(w http.ResponseWriter, r *http.Request) {
	prompt := r.URL.Query().Get("prompt")
	if prompt == "" {
		http.Error(w, "Missing 'prompt' query parameter", http.StatusBadRequest)
		return
	}
	fmt.Println("prompt: ", prompt)

	input := map[string]interface{}{
		"prompt": fmt.Sprintf("Instruction: %s\nResponse:", prompt),
	}

	payload, err := json.Marshal(input)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to encode JSON: %v", err), http.StatusInternalServerError)
		return
	}

	resp, err := client.InvokeModel(context.TODO(), &bedrockruntime.InvokeModelInput{
		ModelId:     aws.String(inferenceProfileARN),
		Body:        payload,
		ContentType: aws.String("application/json"),
		Accept:      aws.String("application/json"),
	})
	if err != nil {
		http.Error(w, fmt.Sprintf("InvokeModel failed: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_, err = w.Write(resp.Body)
	if err != nil {
		if e := fmt.Errorf("failed to write response: %v", err); err != nil {
			panic(e)
		}
	}
}
