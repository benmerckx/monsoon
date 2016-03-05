FROM codeurs/nodejs

RUN npm install -g supervisor

EXPOSE 80

CMD ["supervisor", "-w", "/app", "/app/index.js"]