import os
from flask import Flask, request, render_template, redirect, url_for
from dotenv import load_dotenv

# Import search namespaces
from azure.core.credentials import AzureKeyCredential
from azure.search.documents import SearchClient


app = Flask(__name__)

# Azure Search constants
load_dotenv()
search_endpoint = os.getenv('SEARCH_SERVICE_ENDPOINT')
search_key = os.getenv('SEARCH_SERVICE_QUERY_KEY')
search_index = os.getenv('SEARCH_INDEX_NAME')


# Wrapper function for request to search index
def search_query(search_text, filter_by=None, sort_order=None):
    try:

        # Create a search client
        azure_credential = AzureKeyCredential(search_key)
        search_client = SearchClient(search_endpoint, search_index, azure_credential)
        

        # Submit search query
        results =  search_client.search(search_text,
                                        search_mode="all",
                                        include_total_count=True,
                                        filter=filter_by,
                                        order_by=sort_order,
                                        facets=[],
                                        highlight_fields='title',
                                        select = "content, filepath, title, url, id, last_updated")
        return results
        


    except Exception as ex:
        raise ex

# Home page route
@app.route("/")
def home():
    return render_template("default.html")

# Search results route
@app.route("/search", methods=['GET'])
def search():
    try:
        # Get the search terms from the request form
        search_text = request.args["search"]

        # submit the query and get the results
        results = search_query(search_text, "","")

        # render the results
        return render_template("search.html", search_results=results, search_terms=search_text)

    except Exception as error:
        return render_template("error.html", error_message=error)
