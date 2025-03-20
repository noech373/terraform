exports.handler = async () => {
    const timeZone = "Europe/Paris";
    const currentTime = new Date().toLocaleString("fr-FR", { timeZone });

    return {
        statusCode: 200,
        body: JSON.stringify({
            message: "Heure actuelle à Paris et auteur",
            time: currentTime,
            author: "ChatGPT",
        }),
    };
};
